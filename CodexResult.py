# -*- coding: utf-8 -*-
"""Console prototype for '용사 vs 마왕: 시련의 모험'."""

from __future__ import annotations

import random
from collections import Counter
from dataclasses import dataclass, field


TRIALS = ("A", "B", "C", "D")
COURAGES = ("a", "b", "c", "d")
TRIAL_TO_COURAGE = dict(zip(TRIALS, COURAGES))
BASE_STAKE = 100


@dataclass(frozen=True)
class Mode:
    key: str
    demon_count: int
    rounds: int
    trials_per_round: int


@dataclass
class RoundResult:
    round_no: int
    demon_name: str
    trials: list[str]
    courages: list[str | None]
    cleansed: int
    corrupted: int
    notes: list[str] = field(default_factory=list)


class CardPool:
    def __init__(self) -> None:
        self.cards = [trial for trial in TRIALS for _ in range(2)]

    def counts_text(self) -> str:
        counts = Counter(self.cards)
        return "  ".join(f"{trial}x{counts[trial]}" for trial in TRIALS)

    def available_types(self) -> list[str]:
        return [trial for trial in TRIALS if trial in self.cards]

    def remove_one(self, trial: str) -> None:
        self.cards.remove(trial)

    def remove_many(self, trials: list[str]) -> None:
        for trial in trials:
            self.remove_one(trial)

    def has(self, trial: str) -> bool:
        return trial in self.cards

    def selectable(self, count: int, avoided: set[str] | None = None) -> list[str]:
        pool = list(self.cards)
        if avoided:
            preferred = [card for card in pool if card not in avoided]
            if len(preferred) >= count and random.random() < 0.7:
                pool = preferred
        selected: list[str] = []
        for _ in range(count):
            pick = random.choice(pool)
            selected.append(pick)
            pool.remove(pick)
        return selected


class DemonBot:
    def __init__(self, name: str) -> None:
        self.name = name

    def choose_trials(
        self,
        pool: CardPool,
        count: int,
        known_blocked_trials: set[str],
        blind: bool,
    ) -> list[str]:
        avoided = set() if blind else known_blocked_trials
        return pool.selectable(count, avoided)


class Game:
    def __init__(self) -> None:
        self.mode = self.choose_mode()
        self.pool = CardPool()
        self.demons = [DemonBot(f"마왕{chr(65 + i)}") for i in range(self.mode.demon_count)]
        self.companion_type = self.choose_companion_type()
        self.used_specific_companions: set[str] = set()
        self.revealed_companions: set[str] = set()
        self.universal_ban_used = False
        self.total_cleanse = 0
        self.total_corrupt = 0
        self.history: list[RoundResult] = []

    def choose_mode(self) -> Mode:
        modes = {
            "1": Mode("1v1", 1, 2, 3),
            "2": Mode("1v2", 2, 2, 3),
            "3": Mode("1v3", 3, 3, 2),
        }
        print("===== 용사 vs 마왕: 시련의 모험 =====")
        print("모드를 선택하세요.")
        print("  1) 1 vs 1")
        print("  2) 1 vs 2")
        print("  3) 1 vs 3")
        choice = ask_choice("> ", set(modes))
        return modes[choice]

    def choose_companion_type(self) -> str:
        print("\n동료 타입을 선택하세요.")
        print("  1) 특정 동료: 매 라운드 A/B/C/D 중 1명, 중복 불가")
        print("  2) 만능 동료: R1 자동 정화 슬롯, 후속 라운드 밴 능력")
        choice = ask_choice("> ", {"1", "2"})
        return "specific" if choice == "1" else "universal"

    def play(self) -> None:
        for round_no in range(1, self.mode.rounds + 1):
            self.play_round(round_no)
        self.print_final()

    def play_round(self, round_no: int) -> None:
        demon = self.demons[min(round_no - 1, len(self.demons) - 1)]
        count = self.mode.trials_per_round
        blind = round_no == 1
        known_blocked = set(self.revealed_companions)

        print(f"\n--- 라운드 {round_no} / {self.mode.rounds} ({demon.name}) ---")
        print(f"카드풀: {self.pool.counts_text()}  ({len(self.pool.cards)}장)")

        if self.companion_type == "specific":
            trials = demon.choose_trials(self.pool, count, known_blocked, blind)
            result = self.play_specific_round(round_no, demon.name, trials)
        else:
            result = self.play_universal_round(round_no, demon, blind)

        self.pool.remove_many(result.trials)
        self.total_cleanse += result.cleansed
        self.total_corrupt += result.corrupted
        self.history.append(result)
        self.print_round_result(result)

    def play_specific_round(
        self, round_no: int, demon_name: str, trials: list[str]
    ) -> RoundResult:
        available = [trial for trial in TRIALS if trial not in self.used_specific_companions]
        print(f"사용 가능 동료: {' '.join(f'[{trial}]' for trial in available)}")
        companion = ask_choice("동료를 선택하세요> ", set(available)).upper()
        self.used_specific_companions.add(companion)

        courages = ask_courages(
            f"용기 카드를 {len(trials)}개 선택하세요(a/b/c/d, 쉼표 구분)> ",
            len(trials),
        )
        cleansed = 0
        corrupted = 0
        notes: list[str] = []
        activated = False
        for idx, (trial, courage) in enumerate(zip(trials, courages), start=1):
            if trial == companion:
                cleansed += 1
                activated = True
                notes.append(f"슬롯 {idx}: 동료 {companion} 발동, 시련 {trial} 자동 정화")
            elif TRIAL_TO_COURAGE[trial] == courage:
                cleansed += 1
                notes.append(f"슬롯 {idx}: 시련 {trial} vs 용기 {courage} => 정화")
            else:
                corrupted += 1
                notes.append(f"슬롯 {idx}: 시련 {trial} vs 용기 {courage} => 타락")
        if activated:
            self.revealed_companions.add(companion)
            notes.append(f"동료 정체 공개: 동료 {companion}")
        else:
            notes.append("동료 미발동: 정체 비공개")
        return RoundResult(round_no, demon_name, trials, courages, cleansed, corrupted, notes)

    def play_universal_round(
        self, round_no: int, demon: DemonBot, blind: bool
    ) -> RoundResult:
        count = self.mode.trials_per_round
        notes: list[str] = []
        auto_slot: int | None = None
        ban_cards: list[str] = []

        if round_no == 1:
            auto_slot = ask_int(f"자동 정화 슬롯을 선택하세요(1-{count})> ", 1, count)
            trials = demon.choose_trials(self.pool, count, set(), blind)
            courage_count = count - 1
            courages_for_open = [None] * count
            if courage_count:
                chosen = ask_courages(
                    f"자동 슬롯을 제외한 용기 카드를 {courage_count}개 선택하세요> ",
                    courage_count,
                )
                fill = iter(chosen)
                for idx in range(count):
                    if idx != auto_slot - 1:
                        courages_for_open[idx] = next(fill)
            notes.append(f"만능 동료: 슬롯 {auto_slot} 자동 정화")
        else:
            trials = demon.choose_trials(self.pool, count, set(), blind)
            if self.should_use_universal_ban(round_no):
                ban_count = 1 if self.mode.key in {"1v1", "1v2"} else 2
                ban_cards = ask_bans(ban_count, self.pool)
                self.universal_ban_used = True
                notes.append(f"밴 공개: {', '.join(ban_cards)}")
                trials = self.apply_bans_and_reselect(trials, ban_cards, count, demon)
            courages_for_open = ask_courages(
                f"용기 카드를 {count}개 선택하세요(a/b/c/d, 쉼표 구분)> ",
                count,
            )

        cleansed = 0
        corrupted = 0
        for idx, trial in enumerate(trials, start=1):
            courage = courages_for_open[idx - 1]
            if auto_slot == idx:
                cleansed += 1
                notes.append(f"슬롯 {idx}: 만능 동료 자동 정화")
            elif courage and TRIAL_TO_COURAGE[trial] == courage:
                cleansed += 1
                notes.append(f"슬롯 {idx}: 시련 {trial} vs 용기 {courage} => 정화")
            else:
                corrupted += 1
                shown = courage if courage else "-"
                notes.append(f"슬롯 {idx}: 시련 {trial} vs 용기 {shown} => 타락")

        if ban_cards:
            for ban in ban_cards:
                if self.pool.has(ban):
                    self.pool.remove_one(ban)

        return RoundResult(
            round_no, demon.name, trials, courages_for_open, cleansed, corrupted, notes
        )

    def should_use_universal_ban(self, round_no: int) -> bool:
        if self.mode.key in {"1v1", "1v2"}:
            return round_no == 2
        if self.universal_ban_used:
            return False
        print("이번 라운드에 만능 동료 밴을 사용하시겠습니까?")
        print("  1) 사용")
        print("  2) 사용하지 않음")
        return ask_choice("> ", {"1", "2"}) == "1"

    def apply_bans_and_reselect(
        self, trials: list[str], bans: list[str], count: int, demon: DemonBot
    ) -> list[str]:
        kept = list(trials)
        hit = False
        for ban in bans:
            if ban in kept:
                kept.remove(ban)
                hit = True
        if not hit:
            return trials

        temp_cards = list(self.pool.cards)
        for ban in bans:
            if ban in temp_cards:
                temp_cards.remove(ban)
        for trial in kept:
            if trial in temp_cards:
                temp_cards.remove(trial)

        while len(kept) < count and temp_cards:
            pick = random.choice(temp_cards)
            kept.append(pick)
            temp_cards.remove(pick)
        return kept

    def print_round_result(self, result: RoundResult) -> None:
        print("\n[공개!]")
        print(f"  시련: {'  '.join(result.trials)}")
        courage_text = "  ".join(card if card else "*" for card in result.courages)
        print(f"  용기: {courage_text}")
        for note in result.notes:
            print(f"  - {note}")
        print(f"라운드 점수: 정화 {result.cleansed}, 타락 {result.corrupted}")
        print(f"누적 점수: 정화 {self.total_cleanse}, 타락 {self.total_corrupt}")

    def print_final(self) -> None:
        print("\n===== 게임 종료 =====")
        hero_wins = self.total_cleanse >= self.total_corrupt
        net = abs(self.total_cleanse - self.total_corrupt)
        if hero_wins:
            per_demon = BASE_STAKE * (net + 1)
            total = per_demon * self.mode.demon_count
            print(f"용사 승리! 정화 {self.total_cleanse} / 타락 {self.total_corrupt}")
            print(f"마왕 1인당 지불: {per_demon}")
            print(f"용사 총 수익: +{total}")
        else:
            per_demon = BASE_STAKE * net
            total = per_demon * self.mode.demon_count
            print(f"마왕 승리! 정화 {self.total_cleanse} / 타락 {self.total_corrupt}")
            print(f"마왕 1인당 수익: +{per_demon}")
            print(f"용사 총 손실: -{total}")


def ask_choice(prompt: str, allowed: set[str]) -> str:
    normalized = {value.upper() for value in allowed}
    while True:
        value = input(prompt).strip().upper()
        if value in normalized:
            return value
        print(f"잘못된 입력입니다. 가능한 값: {', '.join(sorted(normalized))}")


def ask_int(prompt: str, low: int, high: int) -> int:
    while True:
        value = input(prompt).strip()
        if value.isdigit() and low <= int(value) <= high:
            return int(value)
        print(f"{low}부터 {high} 사이의 숫자를 입력하세요.")


def ask_courages(prompt: str, count: int) -> list[str]:
    while True:
        raw = input(prompt).replace(",", " ").split()
        values = [item.lower() for item in raw]
        if len(values) == count and all(value in COURAGES for value in values):
            return values
        print(f"a/b/c/d 중 {count}개를 입력하세요. 중복 선택 가능합니다.")


def ask_bans(count: int, pool: CardPool) -> list[str]:
    while True:
        print(f"밴 가능 카드: {pool.counts_text()}")
        raw = input(f"밴할 시련 {count}개를 선택하세요(A/B/C/D, 쉼표 구분)> ")
        values = [item.upper() for item in raw.replace(",", " ").split()]
        if len(values) != count or any(value not in TRIALS for value in values):
            print(f"A/B/C/D 중 {count}개를 입력하세요.")
            continue
        available = Counter(pool.cards)
        requested = Counter(values)
        if all(requested[trial] <= available[trial] for trial in requested):
            return values
        print("현재 카드풀에 없는 수량을 밴할 수 없습니다.")


def main() -> None:
    random.seed()
    Game().play()


if __name__ == "__main__":
    main()
