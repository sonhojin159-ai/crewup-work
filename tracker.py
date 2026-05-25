# -*- coding: utf-8 -*-
"""파일 기반 멀티에이전트 오케스트레이터."""

from __future__ import annotations

import json
import subprocess
import threading
import time
from datetime import datetime
from pathlib import Path
from typing import Any

from watchdog.events import FileSystemEvent, FileSystemEventHandler
from watchdog.observers import Observer


CONFIG = {
    "work_dir": r"C:\Users\sonho\Desktop\MA",
    "codex_cmd": [
        "codex.cmd",
        "exec",
        "-C",
        r"C:\Users\sonho\Desktop\MA",
        "--skip-git-repo-check",
        "--sandbox",
        "workspace-write",
    ],
    "agy_cmd": [
        r"C:\Users\sonho\AppData\Local\agy\bin\agy.exe",
        "--print-timeout",
        "10m",
        "--print",
    ],
    "codex_prompt": "commandcenter.md를 읽고 새로운 지시사항을 수행하라. 코드는 CodexResult.py에, 보고는 CodexReport.md에 작성하라.",
    "agy_prompt": "CodexReport.md와 CodexResult.py를 읽고 검수하라. 결과는 AntiReport.md에 작성하라.",
}


WATCHED_FILES = {
    "commandcenter.md": {
        "phase": "코딩중",
        "task": "Codex CLI 자동 호출",
        "command_key": "codex_cmd",
        "prompt_key": "codex_prompt",
    },
    "CodexReport.md": {
        "phase": "검수중",
        "task": "AntiGravity CLI 자동 호출",
        "command_key": "agy_cmd",
        "prompt_key": "agy_prompt",
    },
    "AntiReport.md": {
        "phase": "완료",
        "task": "검수 보고 완료",
        "command_key": None,
        "prompt_key": None,
    },
}


class Orchestrator:
    """파일 변경을 감지하고 Codex/AntiGravity CLI를 순차 실행한다."""

    def __init__(self, config: dict[str, Any]) -> None:
        self.config = config
        self.work_dir = Path(config["work_dir"]).resolve()
        self.logs_dir = self.work_dir / "logs"
        self.status_path = self.work_dir / "status.json"
        self.lock = threading.Lock()
        self.running = False
        self.last_events: dict[str, float] = {}
        self.self_written: dict[str, float] = {}

        self.logs_dir.mkdir(parents=True, exist_ok=True)
        self.update_status("대기", "-", "감시 시작")

    def should_ignore(self, path: str) -> bool:
        file_path = Path(path).resolve()
        name = file_path.name

        if name not in WATCHED_FILES:
            return True

        now = time.monotonic()
        if now - self.self_written.get(name, 0) < 2:
            return True

        if now - self.last_events.get(name, 0) < 2:
            return True

        self.last_events[name] = now
        return False

    def handle_change(self, path: str) -> None:
        name = Path(path).name
        if self.should_ignore(path):
            return

        thread = threading.Thread(target=self.process_event, args=(name,), daemon=True)
        thread.start()

    def process_event(self, name: str) -> None:
        event_config = WATCHED_FILES[name]

        if self.running:
            self.write_log(f"[대기] 이미 에이전트가 실행 중입니다. 순서 대기: {name}")
            print(f"[대기] 이미 에이전트가 실행 중입니다. 순서 대기: {name}")

        with self.lock:
            self.running = True

            try:
                phase = event_config["phase"]
                task = event_config["task"]
                self.update_status(phase, name, task)
                print(f"\n[상태] {name} 변경 감지: {phase}")

                command_key = event_config["command_key"]
                prompt_key = event_config["prompt_key"]

                if command_key and prompt_key:
                    command = [*self.config[command_key], self.config[prompt_key]]
                    success = self.run_with_retry(command, task)
                    if success:
                        self.update_status("대기", name, f"{task} 완료")
                else:
                    self.write_log("[완료] AntiReport.md 변경 감지. 워크플로우가 완료되었습니다.")
                    print("[완료] AntiGravity 검수 보고가 완료되었습니다.")
            finally:
                self.running = False

    def run_with_retry(self, command: list[str], task: str) -> bool:
        for attempt in range(1, 3):
            self.write_log(f"[실행] {task} 시도 {attempt}/2\n명령: {self.format_command(command)}")
            try:
                result = subprocess.run(
                    command,
                    cwd=self.work_dir,
                    capture_output=True,
                    text=True,
                    encoding="utf-8",
                    errors="replace",
                    check=False,
                )
            except OSError as exc:
                self.write_log(f"[예외] {task} 시도 {attempt}/2 실패: {exc}")
                print(f"[경고] {task} 실행 예외, 재시도 준비 중 ({attempt}/2): {exc}")
                time.sleep(2)
                continue

            self.write_log(
                "\n".join(
                    [
                        f"[결과] {task} 시도 {attempt}/2",
                        f"returncode={result.returncode}",
                        "[stdout]",
                        result.stdout.strip() or "(없음)",
                        "[stderr]",
                        result.stderr.strip() or "(없음)",
                    ]
                )
            )

            if result.returncode == 0:
                print(f"[성공] {task} 완료")
                return True

            print(f"[경고] {task} 실패, 재시도 준비 중 ({attempt}/2)")
            time.sleep(2)

        self.update_status("대기", "-", f"{task} 실패")
        self.write_log(f"[에러] {task} 2회 실패")
        print(f"[에러] {task} 2회 실패. logs 폴더를 확인하세요.")
        return False

    def update_status(self, phase: str, last_file: str, current_task: str) -> None:
        status = {
            "phase": phase,
            "last_updated": datetime.now().isoformat(timespec="seconds"),
            "last_file": last_file,
            "current_task": current_task,
        }
        self.write_json(self.status_path, status)
        self.write_log(f"[상태변경] {json.dumps(status, ensure_ascii=False)}")

    def write_json(self, path: Path, data: dict[str, Any]) -> None:
        path.write_text(
            json.dumps(data, ensure_ascii=False, indent=2),
            encoding="utf-8",
        )
        self.self_written[path.name] = time.monotonic()

    def write_log(self, message: str) -> None:
        now = datetime.now()
        log_path = self.logs_dir / f"log_{now.strftime('%Y%m%d_%H%M%S_%f')}.txt"
        log_path.write_text(
            f"{now.isoformat(timespec='seconds')}\n{message}\n",
            encoding="utf-8",
        )
        self.self_written[log_path.name] = time.monotonic()

    @staticmethod
    def format_command(command: list[str]) -> str:
        return " ".join(f'"{part}"' if " " in part else part for part in command)


class ChangeHandler(FileSystemEventHandler):
    """watchdog 이벤트를 오케스트레이터에 전달한다."""

    def __init__(self, orchestrator: Orchestrator) -> None:
        self.orchestrator = orchestrator

    def on_modified(self, event: FileSystemEvent) -> None:
        if event.is_directory:
            return
        self.orchestrator.handle_change(event.src_path)

    def on_created(self, event: FileSystemEvent) -> None:
        if event.is_directory:
            return
        self.orchestrator.handle_change(event.src_path)


def main() -> None:
    work_dir = Path(CONFIG["work_dir"]).resolve()
    work_dir.mkdir(parents=True, exist_ok=True)

    orchestrator = Orchestrator(CONFIG)
    observer = Observer()
    observer.schedule(ChangeHandler(orchestrator), path=str(work_dir), recursive=False)
    observer.start()

    print("멀티에이전트 오케스트레이터 감시 시작")
    print(f"감시 폴더: {work_dir}")
    print("종료하려면 Ctrl+C를 누르세요.")

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print("\n종료 요청을 받았습니다. 감시를 중지합니다.")
    finally:
        observer.stop()
        observer.join()
        orchestrator.update_status("대기", "-", "감시 종료")


if __name__ == "__main__":
    main()
