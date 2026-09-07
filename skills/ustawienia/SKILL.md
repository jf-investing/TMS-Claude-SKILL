---
name: ustawienia
description: Ustawienia wtyczki TMS — gdzie leży plik konfiguracyjny i co można w nim ustawić. Użyj, gdy użytkownik wywoła /tms:ustawienia, zapyta o ustawienia wtyczki, albo gdy zakładanie zadania nie wyszło, bo brakuje konfiguracji.
---

# Ustawienia wtyczki TMS

Konfigurację trzyma plik `tms.json` w katalogu `.claude` w profilu użytkownika.
Ten skill mówi, gdzie on leży, co ma w środku i co da się zmienić. **Edytuje go
człowiek, nie Ty** — Twoja rola to pokazać stan i ścieżkę.

## Wersja

**Ta instrukcja pochodzi z wydania 0.35.0.** Numer jest wpisany w tym pliku, więc
zawsze mówi prawdę o tym, co jest w tej chwili wczytane — nie o tym, co leży
w repozytorium czy w katalogu wtyczek.

Przy pokazywaniu ustawień wypisz go i sprawdź, czy nie ma nowszego wydania:

```bash
curl -s --max-time 10 https://api.github.com/repos/jf-investing/TMS-Claude-SKILL/releases/latest
```

Interesuje Cię `tag_name` (np. `v0.35.0`). Porównaj z numerem wyżej:
- **te same** → dopisz `Wersja: 0.35.0 (najnowsza)`.
- **wydanie nowsze** → dopisz `Wersja: 0.35.0 — jest już 0.35.1` i powiedz, jak
  zaktualizować: w zarządzaniu wtyczkami odświeżyć źródło, potem **zamknąć
  i otworzyć edytor** i zacząć nową rozmowę. Sam nowy numer w oknie wtyczek nie
  wystarczy — dopóki tu widnieje stary, wczytana jest stara instrukcja.
- **zapytanie nie wyszło** (brak sieci, limit GitHuba) → wypisz sam numer, bez
  zgadywania. To nie jest błąd wart tłumaczenia.

## Pokazanie

Sprawdź, czy plik jest, i odczytaj z niego **pola po jednym — nigdy całość**:

```bash
ls ~/.claude/tms.json
grep -v '^[[:space:]]*//' ~/.claude/tms.json | grep -v '"apiKey"'
```

Druga komenda pokazuje wszystko poza kluczem: `baseUrl`, `propose`, `rules`,
`style`, `projectByFolder`. Do bloku niżej potrzeba jeszcze czterech ostatnich
znaków klucza — i tylko tyle:

```bash
grep -o '"apiKey"[[:space:]]*:[[:space:]]*"[^"]*"' ~/.claude/tms.json \
  | sed 's/.*: *"//; s/"$//' | sed -n 's/.*\(.\{4\}\)$/…\1/p'
```

Pusto → `Klucz: brak`. Plik zapisany w jednej linii → pierwsza komenda nie pokaże
nic; wtedy wyciągaj pola pojedynczo, tym samym `grep -o`.

**`cat` na tym pliku jest wyciekiem.** Klucz wypisany raz zostaje w transkrypcie
rozmowy — pliku, który leży na dysku po sesji i którego nikt nie czyści.
Maskowanie w bloku niżej dotyczy wyświetlenia, nie odczytu: gdy zrzucisz cały plik,
pełna wartość jest w zapisie, choćby człowiek zobaczył tylko końcówkę.

**Konfiguracji nie podajesz parserowi JSON-a** — `ConvertFrom-Json`, `jq`,
`JSON.parse` przy błędzie składni przedrukowują wejście w treści błędu, razem
z kluczem. Komentarzy `//` nie wycinasz wyrażeniem regularnym: łatwo zjeść przy
okazji `//` w `https://`, a wtedy parser wywala się i wypisuje wszystko. Zdarzyło
się naprawdę 2026-09-03. Znacznik BOM na początku pliku `grep`owi nie przeszkadza.

Gdyby klucz mimo wszystko wyszedł na wierzch, **powiedz to wprost**: siedzi
w zapisie tej rozmowy, trzeba wydać nowy (Ustawienia → Klucze) i podmienić w pliku.

Pokaż stan w takim bloku, a pod nim pełną ścieżkę:

```
Ustawienia TMS

Wersja:     0.35.0 (najnowsza)
Adres:      https://tms.example.pl
Klucz:      ustawiony (…3k7f)
Propozycje: włączone
Reguły:     Domyślny projekt: TMS. Zadania dla siebie chyba że mówię inaczej.
Styl:       —
Projekty:   2 katalogi (Desktop\OMS → OMS 🚚, Desktop\WMS → WMS)

Plik: C:\Users\<nazwa>\.claude\tms.json
W środku są opisy wszystkich pól i przykłady.
```

Przy `projectByFolder` wypisz liczbę katalogów i same pary, po ludzku — pełnych
ścieżek nie przepisuj, gdy jest ich więcej niż kilka. Pusta mapa → myślnik.

**Klucza nigdy nie wypisujesz w całości** — tylko cztery ostatnie znaki, żeby dało
się rozpoznać, który to. Brak klucza → `Klucz: brak`. Puste pole → myślnik.

Podaj ścieżkę w postaci właściwej dla systemu: na Windowsie z ukośnikami wstecznymi
i pełnym profilem, gdzie indziej `~/.claude/tms.json`. Dopisz, czym otworzyć —
`notepad "$env:USERPROFILE\.claude\tms.json"` na Windowsie.

Gdy człowiek prosi o zmianę ustawienia, powiedz **które pole** w pliku odpowiada za
to, o co pyta, i jakie wartości przyjmuje. Nie edytuj pliku sam — chyba że poprosi
wprost („zmień mi to"), wtedy zmień **tylko** wskazane pole i zachowaj komentarze.

## Gdy pliku nie ma

Utwórz go z szablonu — z komentarzami, pustymi wartościami do uzupełnienia:

```bash
node -e '
const fs=require("fs"), os=require("os"), path=require("path");
const p=path.join(os.homedir(),".claude","tms.json");
if (fs.existsSync(p)) { console.log("plik już jest:", p); process.exit(0) }
fs.writeFileSync(p, `{
  // Adres firmowego TMS, bez ukośnika na końcu.
  // Weź go z paska przeglądarki, np. "https://tms.firma.pl".
  "baseUrl": "",

  // Klucz osobisty. W TMS: Ustawienia → Klucze → „Wydaj klucz".
  // Pokazuje się jeden raz. To Twoja tożsamość — zadania zakładają się
  // pod Twoim nazwiskiem. Nie wysyłaj go nikomu.
  "apiKey": "",

  // true  — po skończonej robocie Claude sam proponuje zadanie do TMS
  // false — zakłada tylko wtedy, gdy wyraźnie poprosisz
  "propose": true,

  // CO wpisywać w zadaniach. Prozą, własnymi słowami. Przykłady:
  //   "Domyślny projekt: WMS. Zadania dla siebie chyba że mówię inaczej."
  //   "Robota w kodzie idzie do puli Fixy. Bez terminu = średni priorytet."
  //   "Nie proponuj zadań z rozmów, w których tylko planujemy."
  "rules": "",

  // JAK mają brzmieć. Dotyczy stylu, nie treści. Przykłady:
  //   "Krótko, bez ozdobników. Opis maksymalnie trzy zdania."
  //   "Opis pełnymi zdaniami, bez wyliczeń."
  //   "Nazwy zadań zaczynaj od czasownika."
  "style": "",

  // Projekt podpowiadany po katalogu, w którym toczy się rozmowa.
  // Klucz to ścieżka na dysku, wartość — nazwa projektu w TMS, dokładnie taka
  // jak w systemie. Liczy się też każdy podkatalog. Przykład:
  //   "projectByFolder": {
  //     "C:\\Users\\jan\\Desktop\\OMS": "OMS 🚚",
  //     "C:\\Users\\jan\\Desktop\\WMS": "WMS"
  //   }
  // Projekt powiedziany wprost w rozmowie zawsze wygrywa z tą mapą.
  "projectByFolder": {}
}
`, "utf8");
console.log("utworzono:", p);
'
```

Potem powiedz, gdzie plik leży, i przeprowadź przez uzupełnienie: adres i klucz są
konieczne, reszta może zostać pusta. **Klucz niech wklei prosto do pliku, nie
w rozmowę** — wklejony w rozmowie zostaje w jej zapisie na dysku. Gdy mimo to
wklei, wpisz go za niego, potwierdź samą końcówką i powiedz wprost, że ta rozmowa
ma go w zapisie, więc dobrze byłoby wydać nowy.

Na koniec sprawdź, czy działa. Klucz i adres bierzesz do zmiennych — w jednej
komendzie z `curl`em, żeby nic nie wyszło na ekran:

```bash
KLUCZ=$(grep -v '^[[:space:]]*//' ~/.claude/tms.json \
  | grep -o '"apiKey"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//; s/"$//')
BASE=$(grep -v '^[[:space:]]*//' ~/.claude/tms.json \
  | grep -o '"baseUrl"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//; s/"$//')
curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $KLUCZ" \
  "$BASE/api/v1/integrations/dictionary"
```

`200` → gotowe. `401` → klucz zły albo odwołany, poproś o nowy. Cokolwiek innego →
pokaż kod i nie zgaduj, co poszło nie tak.
