# Wtyczka: orchestration — wielu agentów Orca pod nadzorem

## Czym to jest

Reguły pracy z `orca orchestration`, zmierzone na żywych przebiegach, plus trzy
skrypty, które prowadzą cały graf zadań (DAG) w shellu — a nie w kontekście modelu.

Bez tego Claude koordynuje graf ręcznie: odpala zadanie, czeka, czyta status, odpala
następne. Każda taka tura czyta od nowa całą rozmowę, więc koszt rośnie kwadratowo.
Na zmierzonym przebiegu 54 zadań: **~176 tur koordynatora → 4**, a do kontekstu wchodzi
**56 006 B → 3 644 B**. W przeliczeniu na odczyty tokenów to ~10,6 mln → ~80 tys.

Druga połowa oszczędności to `--json`. Guide wbudowany w binarkę Orki wsadza tę flagę
do każdego przykładu, a ona potrafi być 26× droższa na `task-list` przy zerowej dodatkowej
treści. Wtyczka to nadpisuje.

## Instalacja

Marketplace firmowy masz już dodany (stamtąd masz TMS), więc wystarczy:

```
/plugin install orchestration@jf-tms
```

Gdyby marketplace'a nie było:

```
/plugin marketplace add jf-investing/TMS-Claude-SKILL
/plugin install orchestration@jf-tms
```

## Czego potrzebujesz

- **Orca** w PATH — wtyczka sama niczego nie instaluje.
  Sprawdzenie: `orca orchestration --help`
- **bash** — na Windowsie wystarczy Git Bash, który i tak masz z gitem.

Jeśli Orca siedzi pod inną nazwą albo ścieżką, ustaw `ORCA_CLI_COMMAND` — skrypty czytają
tę zmienną przed czymkolwiek innym.

## Sprawdzenie po instalacji

W Claudzie napisz: **„odpal check.sh z wtyczki orchestration"**.

To test tylko do odczytu — nie tworzy przebiegów, zadań ani workerów. Przechodzi przez
wszystkie liczby z `SKILL.md` i konfrontuje je z twoją wersją binarki. Same `ok:` znaczą,
że środowisko gra. Jakiekolwiek `FAIL:` znaczy, że Orca się zmieniła i reguły wymagają
przeliczenia — zgłoś, nie obchodź.

Warto odpalić ponownie po każdej aktualizacji Orki.

## Jak tego używać

Nie musisz nic pamiętać — skill wczytuje się sam, kiedy prosisz o rozbicie roboty na
agentów („rozbij to", „kilku agentów", „równolegle", „DAG", „koordynator").

Pod spodem robi jedno wywołanie, które zakłada przebieg i od razu prowadzi cały graf:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/orchestration/plan.sh" \
  --objective "<cel>" --model sonnet --pool 4 <<'SPECS'
pierwsze zadanie
drugie zadanie
SPECS
```

Kody wyjścia mówią, co się stało — i nie kłamią:

| kod | znaczenie |
|-----|-----------|
| 0   | wszystkie zadania się udały |
| 10  | ktoś pyta o decyzję; do kontekstu trafia tylko to pytanie |
| 20  | DAG skończony, ale są zadania FAILED — wypisane z nazwy |
| 30  | DAG stanął i sam się nie ruszy |

Po odpowiedzi na pytanie wraca się przez samo `drive.sh`, bez zakładania przebiegu od nowa.

## Nadzór na żywo

Domyślnie pętlę prowadzi skrypt. Jeśli chcesz patrzeć na bieżąco, powiedz to wprost —
skill ma osobny tryb ręczny (reguły 2–5 w `SKILL.md`). Kosztuje więcej i po to jest
domyślnie wyłączony.

## Worktree wykrywa się sam

Driver nie zakłada, jak twój workspace obsługuje worktree — próbuje `new-child`
(izolacja, własna nazwa nadawana automatycznie), a gdy Orca odmówi, schodzi na
`current` i mówi o tym jednym wierszem. Nikt nie podaje żadnej flagi.

Gdy chcesz wymusić konkretny wariant: `--worktree current` albo
`--worktree new-child --name moja-nazwa`.

**Odmowa startu workera jest teraz głośna.** Do 1.0.0 `worker-start` leciał
z wyciszonym stderr — odmowa oznaczała, że nie startowało nic, nie było o tym ani
słowa, a pierwszy sygnał przychodził po dwóch pełnych `--timeout-ms` (domyślnie
30 minut) i wskazywał pustą listę. Teraz treść odmowy idzie na ekran, a DAG kończy
się od razu kodem **40**, z zadaniami nietkniętymi w `[ready]`.

To jedyny kod wyjścia, który znaczy „nic się nie wydarzyło" — reszta z tabeli wyżej
opisuje przebieg, który faktycznie ruszył.
