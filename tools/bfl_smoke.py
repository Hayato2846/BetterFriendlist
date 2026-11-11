"""Run BFL's isolated Lua smoke tests; only reference preparation uses the network."""

import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time


class SmokeError(Exception):
    pass


def load_manifest(repo):
    manifest = json.loads((repo / "tools/BFL-SmokeTests.json").read_text(encoding="utf-8-sig"))
    if manifest.get("schemaVersion") != 1:
        raise SmokeError("Unsupported smoke manifest schemaVersion")
    sources = manifest["sources"]
    if set(sources) != {"live", "forever", "classic"}:
        raise SmokeError("Manifest must pin live, forever and classic sources")
    for name, source in sources.items():
        if not re.fullmatch(r"[0-9a-f]{40}", source["revision"]):
            raise SmokeError(f"{name}: expected a full source commit SHA")
    files = []
    allowed = {"{repo}", "{references}"} | {"{" + name + "}" for name in sources}
    for test in manifest["tests"]:
        if not re.fullmatch(r"BFL-[A-Za-z0-9]+Smoke\.lua", test["file"]):
            raise SmokeError(f"Invalid smoke filename: {test['file']}")
        if not test["arguments"] or any(arg not in allowed for arg in test["arguments"]):
            raise SmokeError(f"{test['file']}: invalid argument tokens")
        files.append(test["file"])
    if len(files) != len(set(files)):
        raise SmokeError("Duplicate test in smoke manifest")
    actual = {path.name for path in (repo / "tools").glob("*Smoke.lua")}
    if actual != set(files):
        raise SmokeError(
            f"Smoke inventory mismatch; unregistered: {sorted(actual - set(files))}; "
            f"missing files: {sorted(set(files) - actual)}"
        )
    if not files:
        raise SmokeError("Smoke manifest contains no tests")
    return manifest


def source_names(test, sources):
    if "{references}" in test["arguments"]:
        return set(sources)
    return {name for name in sources if "{" + name + "}" in test["arguments"]}


def default_references(repo):
    if os.environ.get("BFL_REFERENCES_ROOT"):
        return Path(os.environ["BFL_REFERENCES_ROOT"]).resolve()
    for parent in repo.parents:
        candidate = parent / "references"
        if candidate.is_dir():
            return candidate
    raise SmokeError("WoW references not found. Set -ReferenceRoot or BFL_REFERENCES_ROOT.")


def git(root, *args):
    result = subprocess.run(
        ["git", "-C", str(root), *args], capture_output=True, text=True,
        encoding="utf-8", errors="replace", timeout=180, check=False,
    )
    if result.returncode:
        raise SmokeError(f"git {' '.join(args)} failed in {root}: {result.stderr.strip()}")
    return result.stdout.strip()


def prepare_references(manifest, root):
    """Provision a dedicated CI directory; never reset an existing local checkout."""
    root.mkdir(parents=True, exist_ok=True)
    for flavor, source in manifest["sources"].items():
        target = root / f"wow-ui-source-{flavor}"
        if target.exists():
            if git(target, "rev-parse", "HEAD") != source["revision"]:
                raise SmokeError(f"{target} is not at the pinned revision; use a fresh reference directory")
            if git(target, "status", "--porcelain", "--untracked-files=all"):
                raise SmokeError(f"{target} has local changes; refusing to replace them")
        else:
            target.mkdir()
            git(target, "init")
            git(target, "remote", "add", "origin", source["repository"])
            git(target, "config", "core.autocrlf", "false")
            git(target, "sparse-checkout", "init", "--cone")
            git(target, "sparse-checkout", "set", "Interface/AddOns")
            git(target, "fetch", "--depth=1", "--filter=blob:none", "origin", source["revision"])
            git(target, "checkout", "--detach", "FETCH_HEAD")
        version = (target / "version.txt").read_text(encoding="utf-8-sig").strip()
        if version != source["version"]:
            raise SmokeError(f"{flavor}: pinned build mismatch: {version} != {source['version']}")
        print(f"[OK] {flavor}: {source['revision']} ({version})", flush=True)


def text_output(value):
    return value.decode("utf-8", errors="replace") if isinstance(value, bytes) else (value or "")


def run_process(command, repo, timeout):
    start = time.monotonic()
    try:
        process = subprocess.run(
            command, cwd=repo, capture_output=True, text=True, encoding="utf-8",
            errors="replace", timeout=timeout, check=False,
        )
        status = "PASS" if process.returncode == 0 else "FAIL"
        output = process.stdout + process.stderr
        code = process.returncode
    except subprocess.TimeoutExpired as error:
        status, code = "TIMEOUT", None
        output = text_output(error.stdout) + text_output(error.stderr)
    return {"status": status, "exitCode": code, "seconds": round(time.monotonic() - start, 3), "output": output}


def run_tests(options, manifest):
    tests = manifest["tests"]
    if options.test:
        requested = set(options.test)
        known = {test["file"] for test in tests}
        if requested - known:
            raise SmokeError(f"Unknown smoke test(s): {sorted(requested - known)}")
        tests = [test for test in tests if test["file"] in requested]
    excluded = []
    if options.mode == "Portable":
        excluded = [test["file"] for test in tests if source_names(test, manifest["sources"])]
        if options.test and excluded:
            raise SmokeError(f"Requested tests require -Mode Full: {excluded}")
        tests = [test for test in tests if test["file"] not in excluded]
    print(f"[BFL] Smoke tests: {options.mode}; {len(tests)} selected / {len(manifest['tests'])} registered", flush=True)
    if excluded:
        print(f"[INFO] {len(excluded)} source-dependent tests excluded by Portable mode; run Full for complete coverage.", flush=True)
    if not tests:
        raise SmokeError("No smoke tests selected")
    if options.list:
        for test in tests:
            print(f"{test['file']}: {' '.join(test['arguments'])}")
        return 0
    lua = shutil.which(options.lua)
    if not lua:
        raise SmokeError(f"Lua 5.4 not found: {options.lua}. Install it or pass -Lua.")
    version = subprocess.run([lua, "-v"], capture_output=True, text=True, timeout=10, check=True)
    if not re.search(r"Lua 5\.4\.", version.stdout + version.stderr):
        raise SmokeError("These smoke tests require Lua 5.4 (not LuaJIT or Lua 5.1).")
    print(f"[BFL] {(version.stdout + version.stderr).strip()}", flush=True)
    needed = set().union(*(source_names(test, manifest["sources"]) for test in tests))
    tokens = {"{repo}": str(options.repo)}
    references = {}
    if needed:
        root = options.reference_root or default_references(options.repo)
        tokens["{references}"] = str(root)
        for name in sorted(needed):
            path = root / f"wow-ui-source-{name}"
            if not (path / "Interface/AddOns").is_dir() or not (path / "version.txt").is_file():
                raise SmokeError(f"Missing {name} WoW source at {path}. Set -ReferenceRoot or prepare CI references.")
            tokens["{" + name + "}"] = str(path)
            references[name] = {"path": str(path), "revision": git(path, "rev-parse", "HEAD"),
                                "version": (path / "version.txt").read_text(encoding="utf-8-sig").strip()}
            print(f"[BFL] {name}: {references[name]['revision']} ({references[name]['version']})", flush=True)
    results = []
    for test in tests:
        result = run_process([lua, str(options.repo / "tools" / test["file"]),
                              *(tokens[arg] for arg in test["arguments"])], options.repo, options.timeout)
        result["file"] = test["file"]
        results.append(result)
        print(f"[{result['status']}] {test['file']} ({result['seconds']:.3f}s)", flush=True)
        if result["output"].strip():
            print(result["output"].rstrip(), flush=True)
    failures = sum(result["status"] != "PASS" for result in results)
    summary = f"Smoke tests: {len(results) - failures}/{len(results)} passed; {failures} failed; {len(excluded)} excluded by mode."
    print(f"[{'FAIL' if failures else 'OK'}] {summary}", flush=True)
    if options.report:
        options.report.parent.mkdir(parents=True, exist_ok=True)
        options.report.write_text(json.dumps({"mode": options.mode, "registered": len(manifest["tests"]),
            "references": references, "excluded": excluded, "results": results}, indent=2) + "\n", encoding="utf-8")
    if os.environ.get("GITHUB_STEP_SUMMARY"):
        with open(os.environ["GITHUB_STEP_SUMMARY"], "a", encoding="utf-8") as stream:
            stream.write(f"\n### Lua smoke tests ({options.mode})\n\n{summary}\n\n| Test | Result | Seconds |\n|---|---|---:|\n")
            for result in results:
                stream.write(f"| {result['file']} | {result['status']} | {result['seconds']:.3f} |\n")
    return 1 if failures else 0


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    run = commands.add_parser("run")
    run.add_argument("--repo", type=Path, default=Path(__file__).resolve().parent.parent)
    run.add_argument("--mode", choices=["Portable", "Full"], default="Portable")
    run.add_argument("--reference-root", type=Path)
    run.add_argument("--lua", default=os.environ.get("BFL_LUA", "lua"))
    run.add_argument("--timeout", type=float, default=60)
    run.add_argument("--report", type=Path)
    run.add_argument("--test", action="append")
    run.add_argument("--list", action="store_true")
    prepare = commands.add_parser("prepare-references")
    prepare.add_argument("--repo", type=Path, default=Path(__file__).resolve().parent.parent)
    prepare.add_argument("--reference-root", type=Path, required=True)
    options = parser.parse_args(argv)
    try:
        options.repo = options.repo.resolve()
        manifest = load_manifest(options.repo)
        if options.command == "prepare-references":
            prepare_references(manifest, options.reference_root.resolve())
            return 0
        if options.timeout <= 0:
            raise SmokeError("Timeout must be positive")
        if options.reference_root:
            options.reference_root = options.reference_root.resolve()
        return run_tests(options, manifest)
    except (SmokeError, OSError, ValueError, KeyError, subprocess.SubprocessError) as error:
        print(f"[FAIL] {error}", file=sys.stderr, flush=True)
        return 2


if __name__ == "__main__":
    sys.exit(main())
