# TMS — instrukcje dla agenta

To repozytorium jest wtyczką do firmowego TMS: zakładanie zadań, materiały do
weryfikacji, zmiana statusów, raporty wykonanej roboty. Treść instrukcji nie
zależy od żadnego konkretnego narzędzia — wystarczy powłoka i czytanie plików.

## Kiedy co przeczytać

Instrukcje leżą w `skills/`. **Nie czytaj ich na zapas** — otwórz ten plik, który
pasuje do tego, o czym właśnie jest rozmowa:

| Pada w rozmowie | Przeczytaj |
| --- | --- |
| „załóż zadanie", „wrzuć to do TMS", „dopisz materiały", „popraw opis", „zaczynam to", „oznacz jako zrobione", „oddaj do weryfikacji", „czemu to stoi", „odhacz punkt", „załóż projekt" | `skills/zadanie/SKILL.md` |
| „co dziś zrobione", „podsumuj tydzień", „co Wojtek zrobił wczoraj", „raport z sierpnia", „nad czym siedzę", „zapisz to do dziennika" | `skills/raport/SKILL.md` |
| „ustawienia", „gdzie leży klucz", „jaka wersja", a także gdy cokolwiek z powyższych nie wyszło, bo brakuje konfiguracji | `skills/ustawienia/SKILL.md` |

Pełna lista wyzwalaczy stoi we frontmatterze każdego z tych plików, w polu
`description`. Narzędzia, które same wykrywają skille (Claude Code, Copilot CLI),
czytają ją i otwierają plik za Ciebie — wtedy ta tabela jest zbędna, ale nie
przeszkadza.

## Trzy rzeczy, które obowiązują zawsze

Poniższe łamie się **pierwszym ruchem** — zanim otworzysz jakikolwiek skill i zanim
zdąży Cię ostrzec. Dlatego stoją tutaj, a nie tylko tam.

### 1. Klucza nie wypisujesz — nigdzie

Konfigurację znajdujesz w trzech miejscach po kolei; bierzesz pierwsze istniejące:
`$TMS_CONFIG` → `~/.tms/config.json` → `~/.claude/tms.json`.

Klucz idzie **do zmiennej, w tej samej komendzie co wywołanie**. Nic nie drukuje:

```bash
CFG=$(for p in "$TMS_CONFIG" ~/.tms/config.json ~/.claude/tms.json; do [ -f "$p" ] && echo "$p" && break; done)
KLUCZ=$(grep -v '^[[:space:]]*//' "$CFG" \
  | grep -o '"apiKey"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//; s/"$//')
BASE=$(grep -v '^[[:space:]]*//' "$CFG" \
  | grep -o '"baseUrl"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//; s/"$//')
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/dictionary"
```

**`cat` na tym pliku jest wyciekiem** — wszystko, co wyjdzie z komendy, zostaje
w zapisie rozmowy, który leży na dysku po sesji i którego nikt nie czyści.
**Konfiguracji nie podajesz też parserowi JSON-a** (`jq`, `ConvertFrom-Json`,
`JSON.parse`): przy błędzie składni przedrukowują wejście razem z kluczem, a plik
ma komentarze `//`, więc o błąd nietrudno. Zdarzyło się naprawdę 2026-09-03 i klucz
trzeba było wymienić. Pola wyciągasz `grep`em, po jednym.

### 2. Polską treść wysyłasz plikiem

Tytuł, opis, komentarz, materiały — **wszystko, co przeczyta potem człowiek** —
idzie przez `--data-binary @plik.json`, nigdy wpisane wprost w komendę. Ogonki
wpisane w argument potrafią dojść jako krzaki, a **wygląda to na sukces**: serwer
odpowiada `200`, numer zadania wraca, a rozsypany tytuł wychodzi dopiero wtedy, gdy
ktoś na to spojrzy w TMS.

Wprost w komendzie zostają wyłącznie wartości techniczne: statusy, daty, numery,
`true`/`false`. Plik zakładaj **ścieżką względną** (curl na Windowsie nie widzi
bashowego `/tmp`) i kasuj po wysłaniu.

### 3. Numer zadania zawsze z linkiem

Ilekroć wymieniasz zadanie, dawaj `<baseUrl>/tasks/<numer>` — założone, ruszone,
znalezione, wspomniane mimochodem. Sam numer zmusza człowieka do szukania po
numerku, czyli do tej roboty, której wtyczka ma go oszczędzić.

**Hosta nie bierzesz z pamięci ani z przykładów w tych plikach.** Gdy `baseUrl`
poszedł wyłącznie jako zmienna powłoki, nigdy nie trafił do Twojego kontekstu —
działający `curl` **nie jest** dowodem, że go znasz. Zanim podasz pierwszy link,
wypisz samo to pole (wolno, to nie klucz):

```bash
CFG=$(for p in "$TMS_CONFIG" ~/.tms/config.json ~/.claude/tms.json; do [ -f "$p" ] && echo "$p" && break; done)
grep -v '^[[:space:]]*//' "$CFG" | grep -o '"baseUrl"[[:space:]]*:[[:space:]]*"[^"]*"'
```

---

*Ten plik jest drogowskazem, nie kopią — wczytuje się w całości przy każdej
rozmowie w tym repo, więc treść instrukcji zostaje w `skills/`. Gdy przybywa
reguły, jej miejsce jest w skillu; tutaj trafia tylko to, co trzeba wiedzieć,
zanim otworzy się jakikolwiek plik.*
