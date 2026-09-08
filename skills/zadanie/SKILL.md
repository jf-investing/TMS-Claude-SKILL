---
name: zadanie
description: Zadania i projekty w firmowym TMS — zakładanie zadań, materiały do weryfikacji, poprawa opisu, zmiana statusu i zakładanie projektów. Użyj po skończonej robocie, żeby zaproponować zadanie do TMS i opisać, co zrobione, oraz kiedy użytkownik prosi „załóż zadanie", „wrzuć to do TMS", „załóż zadanie do puli", „niech ktoś to weźmie", „dodaj task", „zrób z tego zadanie", „dopisz materiały", „popraw opis zadania", „sformatuj to zadanie", „załóż projekt", „odhacz punkt", „co zostało w zadaniu", „co zostało w projekcie", „co wisi w puli", „rozdziel niczyje zadania", „kto co bierze", „na czym stanęliśmy", „co następne", „czemu to stoi", „co blokuje to zadanie", „załóż zadanie z tego PR-a", „co jest na tym zdjęciu w zadaniu", „przeczytaj załącznik", „obejrzyj zrzut z zadania", „co pisali w uwagach", „czemu wróciło do poprawy", a także gdy mówi „zaczynam to", „biorę się za to", „oznacz jako zrobione", „oddaj do weryfikacji", „to stoi", „odstawiam to", „czekam na kogoś z tym", „wracam do tego" albo „zmień status zadania", „popraw nazwę zadania", „zmień tytuł", „podnieś priorytet", „to już nie jest pilne".
---

# Zadania w TMS

Po skończonej robocie proponujesz zadanie i po potwierdzeniu zakładasz je w TMS.
Zadanie idzie na produkcję pod nazwiskiem właściciela klucza.

## Ustawienia

Wszystko siedzi w jednym pliku JSON — poza tym repo, klucz nigdy do gita:

```json
{
  "baseUrl": "https://tms.firma.pl",
  "apiKey": "tms_...",
  "propose": true,
  "rules": "Domyślny projekt: TMS. Zadania dla siebie chyba że mówię inaczej.",
  "style": "Krótko, bez ozdobników. Opis maksymalnie trzy zdania.",
  "projectByFolder": { "C:\\Users\\jan\\Desktop\\OMS": "OMS 🚚" }
}
```

Plik szukasz w trzech miejscach, po kolei, i bierzesz pierwsze, które istnieje:

1. ścieżka ze zmiennej `TMS_CONFIG`, gdy jest ustawiona,
2. `~/.tms/config.json` — miejsce niezwiązane z żadnym narzędziem,
3. `~/.claude/tms.json` — tam, gdzie plik leży u wszystkich, którzy zaczynali od
   wtyczki do Claude'a.

Trzecie miejsce zostaje na stałe: **nikt nie musi nic przenosić.** Nowe instalacje
zakładaj w drugim — to samo repo podpina się dziś także pod inne narzędzia (patrz
`AGENTS.md` w korzeniu), a katalog `.claude` jest wtedy mylący.

Brak pliku albo brak `apiKey` → powiedz, że skill nie jest skonfigurowany, i odeślij
do `/tms:ustawienia`. Ta sama komenda ustawienia pokazuje i objaśnia. Gdyby przyszło
Ci coś w pliku zmieniać — NIE kasuj komentarzy `//`.

`propose: false` → nie proponuj z własnej inicjatywy, zakładaj tylko na wyraźną
prośbę. `rules` to prywatne ustalenia tej osoby — trzymaj się ich, chyba że
w rozmowie padło co innego. `style` dotyczy brzmienia: długości opisu, tonu, tego
czy używać wyliczeń. Reguły mówią CO wpisać, styl JAK to napisać.

**Reguły mówią też, jak masz się zachować** — nie tylko co wpisać w pola zadania.
„Jako kierownik zamykam swoje zadania sam" jest regułą dokładnie tak samo jak
„domyślny projekt: WMS". Gdy reguła odpowiada na pytanie, które i tak byś zadał,
**tego pytania nie zadajesz** — robisz po jej myśli i mówisz, którą zastosowałeś.
Skąd się te reguły biorą, mówi sekcja niżej.

`projectByFolder` to mapa katalog na dysku → projekt w TMS. Gdy rozmowa toczy się
w takim katalogu albo gdziekolwiek pod nim, podstaw ten projekt do propozycji
zamiast pytać. Pasuje kilka ścieżek → wygrywa najdłuższa (najbardziej szczegółowa).
Projekt powiedziany wprost w rozmowie ma pierwszeństwo, a nazwy spoza słownika
nie wpisujesz nawet z mapy — powiedz wtedy, że tego projektu nie ma w Twoim
zasięgu. Katalog spoza mapy: ustalasz projekt jak dotąd.

## Odczyt ustawień

**Klucza nie wypisujesz — nigdzie.** Wszystko, co wyjdzie z komendy, zostaje
w transkrypcie rozmowy: pliku na dysku, który po sesji nie znika i którego nikt nie
czyści. `cat` na tym pliku jest wyciekiem, choćby blok pokazany potem
człowiekowi maskował klucz do czterech znaków — maskowanie dotyczy wyświetlenia,
nie odczytu.

Klucz bierzesz do zmiennej, w tej samej komendzie co wywołanie. Nic nie drukuje:

```bash
CFG=$(for p in "$TMS_CONFIG" ~/.tms/config.json ~/.claude/tms.json; do [ -f "$p" ] && echo "$p" && break; done)
KLUCZ=$(grep -v '^[[:space:]]*//' "$CFG" \
  | grep -o '"apiKey"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//; s/"$//')
BASE=$(grep -v '^[[:space:]]*//' "$CFG" \
  | grep -o '"baseUrl"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//; s/"$//')
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/dictionary"
```

W PowerShellu to samo, też bez drukowania:

```powershell
$CFG   = @($env:TMS_CONFIG, "$env:USERPROFILE\.tms\config.json",
           "$env:USERPROFILE\.claude\tms.json") |
         Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
$cfg   = Get-Content $CFG -Raw
$KLUCZ = [regex]::Match($cfg, '"apiKey"\s*:\s*"([^"]*)"').Groups[1].Value
$BASE  = [regex]::Match($cfg, '"baseUrl"\s*:\s*"([^"]*)"').Groups[1].Value
```

Znacznik BOM na początku pliku niczego tu nie psuje — szukasz pola, nie początku
pliku.

Resztę pól — `propose`, `rules`, `style`, `projectByFolder` — wolno pokazać, więc
czytasz je bez linii z kluczem:

```bash
CFG=$(for p in "$TMS_CONFIG" ~/.tms/config.json ~/.claude/tms.json; do [ -f "$p" ] && echo "$p" && break; done)
grep -v '^[[:space:]]*//' "$CFG" | grep -v '"apiKey"'
```

Plik zapisany w jednej linii → ta komenda nie pokaże nic. Wtedy bierzesz pola
pojedynczo, tym samym `grep -o`, co klucz.

**Konfiguracji nie podajesz parserowi JSON-a.** `ConvertFrom-Json`, `jq`,
`JSON.parse` przy błędzie składni **przedrukowują wejście w treści błędu** — razem
z kluczem. A o błąd nietrudno: plik ma komentarze `//`, więc naturalnym ruchem jest
wyciąć je wyrażeniem regularnym, po czym regex zjada `//` w `https://` i parser się
wywraca. Zdarzyło się naprawdę 2026-09-03 i klucz trzeba było wymienić. Pola
wyciągasz `grep`em, po jednym, i na tym koniec.

Gdyby klucz mimo wszystko wyszedł na wierzch — błąd parsera, wklejenie w rozmowie,
własna komenda — **powiedz to wprost**: klucz siedzi w zapisie tej rozmowy, trzeba
wydać nowy w TMS (Ustawienia → Klucze) i podmienić go w pliku. Nikt się o tym sam
nie dowie.

Nie pytaj o klucz w rozmowie. W przykładach niżej `$KLUCZ` to `apiKey`, a `$BASE` to
`baseUrl` — podstawione tak, jak wyżej.

## Reguły z rozmowy

Człowiek raz na jakiś czas mówi coś, co nie dotyczy tej jednej roboty, tylko
**każdej następnej**: „skoro jestem kierownikiem projektu, moje zadania zamykaj od
razu", „zadania z tego repozytorium zakładaj w projekcie WMS", „nie pytaj mnie
o priorytet, domyślnie średni". To jest reguła, nie polecenie na teraz.

**Powiedziana w rozmowie ginie razem z rozmową.** Następna sesja startuje z pustą
głową i pyta o to samo, co poprzednia — a człowiek widzi wtyczkę, która go nie
słucha. Dlatego regułę usłyszaną w rozmowie **proponujesz zapisać** do `rules`.

Poznajesz ją po tym, że mówi o zasadzie, a nie o tym jednym zadaniu: pada „od
teraz", „zawsze", „domyślnie", „nie pytaj mnie o", „skoro jestem…", albo człowiek
drugi raz z rzędu poprawia Cię w tę samą stronę. Jednorazowe „tym razem zamknij"
regułą nie jest.

Pytasz krótko, cytując to, co dopiszesz — **dosłownie tak, jak trafi do pliku**:

```
Zapisać to na stałe?
  „Jako kierownik projektu zamykam swoje zadania sam, bez pytania o weryfikację."
[zapisz / nie]
```

Dopiero po zgodzie dopisujesz. Reguła idzie **na koniec** dotychczasowych, jednym
zdaniem, w pierwszej osobie — tak, jak człowiek napisałby to sam. Treść reguły
**wysyłasz plikiem** — to polski tekst, więc obowiązuje ta sama zasada co przy
zadaniach (patrz „Treść ZAWSZE z pliku"). Skryptu też nie wklejasz w `node -e`:

```bash
cat > regula.txt << 'TEKST'
Jako kierownik projektu zamykam swoje zadania sam, bez pytania o weryfikację.
TEKST

cat > dopisz-regule.js << 'SKRYPT'
const fs=require("fs"), os=require("os"), path=require("path");
const UKOSNIK=String.fromCharCode(92);
const p=[process.env.TMS_CONFIG, path.join(os.homedir(),".tms","config.json"),
         path.join(os.homedir(),".claude","tms.json")].find(x=>x && fs.existsSync(x));
if(!p){ console.log("brak pliku konfiguracyjnego"); process.exit(1) }
const t=fs.readFileSync(p,"utf8");
const i=t.indexOf('"rules"');
if(i<0){ console.log("brak pola rules"); process.exit(1) }
const a=t.indexOf('"', t.indexOf(":", i)+1);
let b=a+1; while(t[b]!=='"'){ if(t[b]===UKOSNIK) b++; b++ }
const stare=t.slice(a+1,b);
const nowa=fs.readFileSync("regula.txt","utf8").trim()
  .split(UKOSNIK).join(UKOSNIK+UKOSNIK).split('"').join(UKOSNIK+'"');
fs.writeFileSync(p, t.slice(0,a+1)+(stare?stare+" ":"")+nowa+t.slice(b), "utf8");
console.log("dopisane do:", p);
SKRYPT

node dopisz-regule.js
```

Ruszasz **wyłącznie to jedno pole**, reszta pliku zostaje bajt w bajt — razem
z komentarzami `//`, które ktoś czyta, gdy zagląda tam ręcznie.

**Odwrotnego ukośnika nie wpisujesz w skrypcie wprost** — stąd `UKOSNIK`. Zmierzone
2026-09-08: ten sam skrypt wklejony w komendę stracił po drodze połowę ukośników
i wyrażenie regularne przestało się kompilować. Powłoka, narzędzie, warstwa po
drodze — każda z nich potrafi je zjeść, a `String.fromCharCode(92)` przechodzi
wszędzie bez zmian.

**Skrypt nie drukuje z pliku niczego poza ścieżką i to jest celowe.** W tym samym
pliku leży klucz, a wypisany raz zostaje w zapisie rozmowy na zawsze. Z tego samego
powodu nie podajesz pliku `JSON.parse`'owi ani `jq`: przy byle błędzie składni
parser przedrukowuje całe wejście w treści błędu, razem z kluczem (patrz „Odczyt
ustawień").

`brak pola rules` znaczy plik starszy niż to pole — powiedz to i odeślij do
`/tms:ustawienia`, tam jest szablon z kompletem pól. Nie dopisuj pola sam.

Po zapisie jedno zdanie: co zapisane i że da się to zmienić w `/tms:ustawienia`.
Poprawiasz i kasujesz reguły tak samo — na prośbę, pokazując wcześniej nową treść
całego pola.

**Czego nie zapisujesz:** rzeczy rzuconych w złości albo w pośpiechu („dobra,
zamykaj wszystko"), ustaleń dotyczących jednego zadania, i niczego, czego człowiek
nie potwierdził. Reguła zapisana po cichu jest gorsza niż jej brak — działa
miesiącami, a nikt nie pamięta, skąd się wzięła.

## Treść ZAWSZE z pliku

**Cokolwiek napisanego po polsku wysyłasz przez plik, nigdy wpisane wprost
w komendę.** Tytuł, opis, materiały, komentarz, punkt checklisty, nazwa projektu —
wszystko, co czyta potem człowiek.

```bash
cat > tresc.json << 'JSON'
{"title":"Poprawić eksport zamówień","description":"<p>Ogonki i „cudzysłowy” dochodzą całe.</p>"}
JSON
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  --data-binary @tresc.json "$BASE/api/v1/integrations/inbound/claude"
```

**Why:** ogonki i cudzysłowy wpisane prosto w komendę potrafią dojść jako krzaki —
zależnie od powłoki i kodowania. Najgorsze jest to, że **wygląda to na sukces**:
serwer odpowiada „przyjąłem", numer zadania wraca, a rozsypany tekst wychodzi
dopiero wtedy, gdy ktoś na to spojrzy w TMS. Zdarzyło się naprawdę — tytuł zapisał
się jako `obs?uga statusu ?Czeka?`.

Wprost w komendzie (`-d '{...}'`) zostają **wyłącznie wartości techniczne**: statusy,
daty, numery, `true`/`false`. Tam nie ma czego zepsuć.

Dotyczy to tak samo **tekstu w adresie** — `--data-urlencode "title=Dziennik pracy —
Jan Kowalski"` psuje się dokładnie tak samo jak `-d`, choć nie wygląda na treść.
Tam, gdzie w argumencie miałby stanąć polski napis, wstawiasz plik: `--data-urlencode
"title@tytul.txt"`. Plik zapisz **bez końcowego znaku nowej linii** — `printf '%s'`,
nie `echo` i nie heredoc — bo curl zakodowałby go jako `%0A` i tytuł przestałby
pasować co do znaku.

### Ścieżki plików

**Żadnego `/tmp`.** Curl na Windowsie to program Windows i bashowego `/tmp` nie widzi:
kończy się `error encountered when reading a file` albo, gorzej, wysłaniem zera bajtów
— serwer odpowiada wtedy sukcesem, a treści nie przybyło. Plik zakładasz **ścieżką
względną**, w katalogu, w którym stoisz, i po wszystkim kasujesz.

Heredoc musi być cytowany (`<< 'JSON'`), inaczej powłoka zje ukośniki i `$`.
Po wysłaniu **sprawdź w odpowiedzi, jak zapisał się tekst** — jeśli widzisz krzaki
zamiast ogonków, popraw od razu, zamiast meldować gotowe. Przy zakładaniu zadania
patrzysz na `task.title` z odpowiedzi (patrz „Założenie"); przy zapisach, które
oddają całe zadanie — na to samo pole w nim.

## Numer zadania ZAWSZE z linkiem

**Ilekroć wymieniasz zadanie, dawaj link** — założone, ruszone, oddane, zablokowane,
znalezione przy wyszukiwaniu, wymienione mimochodem w podsumowaniu roboty. Bez wyjątku
i bez czekania, aż ktoś poprosi.

Adres składasz z `baseUrl`: `$BASE/tasks/<numer>`.

**Hosta nie bierzesz z pamięci ani z przykładów w tym pliku.** Gdy `baseUrl` poszedł
wyłącznie jako zmienna powłoki — a tak właśnie ma iść, bo tą samą komendą leci klucz —
to nigdy nie trafił do Twojego kontekstu. Działający `curl` **nie jest** dowodem, że go
znasz: host siedzi tam w zmiennej, której nie widzisz. Zanim podasz pierwszy link
w rozmowie, wypisz samo to pole (wolno, to nie klucz):

```bash
CFG=$(for p in "$TMS_CONFIG" ~/.tms/config.json ~/.claude/tms.json; do [ -f "$p" ] && echo "$p" && break; done)
grep -v '^[[:space:]]*//' "$CFG" | grep -o '"baseUrl"[[:space:]]*:[[:space:]]*"[^"]*"'
```

Zmyślony host wygląda tak samo wiarygodnie jak prawdziwy — nikt go nie łapie na oko,
wychodzi dopiero wtedy, gdy człowiek kliknie.

```
Zadanie #1814 czeka na Wojtka jako „Do weryfikacji"
https://tms.firma.pl/tasks/1814
```

Sam numer zmusza człowieka do szukania zadania po numerku — a to jest dokładnie ta
robota, której wtyczka ma go oszczędzić. Przy liście kilku zadań link dawaj przy każdym
(w wierszu albo pod nim), nie tylko przy pierwszym.

Wyjątek jest jeden: gdy w tej samej odpowiedzi ten sam link już padł — nie powtarzaj go
przy każdej wzmiance.

## Słownik — ZAWSZE PIERWSZY

**Zanim cokolwiek zaproponujesz i zanim cokolwiek wyślesz, pobierz słownik.**
Raz na rozmowę, ale przed pierwszą propozycją — bez wyjątków.

```bash
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/dictionary"
```

Zwraca `projects`, `pools` (z `projectId`), `users`, `priorities` oraz `me`
z `canAssignToOthers` i `canCreateProject`. `projects` i `pools` są przycięte do
uprawnień właściciela klucza — **czego tam nie ma, tego on nie może**. `users` to
wyjątek: lista osób przychodzi zawsze, bo czytanie nazwisk to nie to samo co
rozdawanie zadań. Prawem do przypisywania rządzi `canAssignToOthers` i dotyczy
ono wyłącznie zapisu.

Każdy projekt niesie też, kim się w nim jest i kto nim kieruje: `myRole` to rola
właściciela klucza (`kierownik`, `uczestnik` albo `null`, gdy projekt tylko widzi),
a `owners` i `managers` to imienne listy z numerami. **Skoro znasz imiona, używaj
ich** — „projektem kieruje Wojciech Kulus" mówi człowiekowi, kogo zapytać, a „brak
uprawnień" zostawia go z niczym.

### Sprawdzenie uprawnień przed działaniem

**Obecność projektu na liście nie znaczy jeszcze, że da się w nim założyć zadanie.**
Słownik pokazuje też projekty, które właściciel klucza wyłącznie widzi — te mają
`myRole` na `null` i kończą się odmową `403`. Sprawdź rolę, zanim ułożysz
propozycję, i przy jej braku od razu nazwij osobę, do której trzeba się zwrócić:

```
W projekcie „Amazon Hiszpania" jesteś obserwatorem — nie założysz tam zadania.
O dostęp poproś Jakuba Szyperkiego, właściciela projektu.

Możesz też wybrać inny projekt (TMS ✅, OMS 🚚, …) albo założyć zadanie bez projektu.
```

Projektu, którego w słowniku nie ma w ogóle, właściciel klucza nawet nie widzi —
powiedz to wprost, zamiast obiecywać dostęp.

Nie próbuj „na wszelki wypadek" — odmowa z serwera po pokazaniu gotowej
propozycji wygląda, jakby coś się zepsuło, a to zwykły brak uprawnień.

To samo dotyczy reszty:
- `canAssignToOthers` na `false` → wykonawcą jest wyłącznie właściciel klucza,
  nawet jeśli rozmowa sugeruje kogoś innego. Powiedz o tym, nie zgaduj.
- `canCreateProject` na `false` → nie proponuj zakładania projektu.
- Puli nie ma na liście dla tego projektu → nie wpisuj jej.
- Kogo nie ma w `owners` ani `managers` danego projektu, tego nie mianuj jego
  kierownikiem — ani w zdaniu do człowieka, ani przy wyborze recenzenta.

Nie zgaduj projektów, pul ani ludzi z pamięci, z rozmowy ani z tego repo. Jedynym
źródłem prawdy jest słownik pobrany TERAZ.

## Zakładanie projektu

Gdy zadanie nie pasuje do żadnego istniejącego projektu, a `canCreateProject`
w słowniku jest `true`, możesz zaproponować nowy. **Tylko na wyraźną prośbę albo
gdy człowiek sam powie, że projektu brakuje** — nie zakładaj projektu przy okazji
zakładania zadania.

```bash
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  --data-binary @projekt.json \
  "$BASE/api/v1/integrations/projects"
```

Pola: `name` (min. 3 znaki, musi być unikalna), `description` (HTML jak w opisach
zadań), `status` — `planned` (domyślny), `active`, `on_hold`, `done`.

Zanim wyślesz, pokaż do zatwierdzenia:

```
Nowy projekt w TMS

Nazwa: Automatyzacja raportów magazynowych
Opis:  Zbiera w jednym miejscu robotę wokół raportów z WMS.
       Na razie dwa zadania, ale będzie ich więcej.

Zakładam? [tak / popraw / anuluj]
```

Właścicielem zostaje właściciel klucza. Odpowiedź niesie `id` i `name` — powiedz,
że projekt powstał, i **dopiero teraz** zakładaj w nim zadanie. Świeży projekt nie
ma pul, więc pola „Pula" nie wypełniaj.

Odmowy:
- `403 forbidden` — właściciel klucza nie może zakładać projektów. Sprawdź to
  wcześniej w słowniku, żeby nie dopytywać po fakcie.
- `409 name_taken` — projekt o tej nazwie już istnieje. Pokaż go i zapytaj, czy
  o niego chodziło.
- `400` — nazwa krótsza niż trzy znaki.

## Duplikaty

Zanim pokażesz propozycję, sprawdź, czy tego samego już ktoś nie zgłosił:

Ogonki w szukanej frazie nie mają znaczenia — serwer zdejmuje je po obu stronach,
więc „zwrotow" znajdzie „zwrotów" i odwrotnie. Pisz ją więc **bez ogonków**, jak niżej:
polski tekst wpisany w argument komendy potrafi się po drodze rozsypać (patrz „Ścieżki
plików" i akapit o tekście w adresie), a tutaj nic przez to nie tracisz. Trzon słowa
wystarczy: „termin" znajdzie i „terminy", i „terminów" — ale nie odwrotnie, bo odmiany
serwer nie rozwija.

```bash
curl -s -H "Authorization: Bearer $KLUCZ" \
  --get --data-urlencode "query=filtr termin" --data-urlencode "limit=5" \
  "$BASE/api/v1/integrations/tasks"
```

W `query` daj dwa–trzy nośne słowa z nazwy, którą właśnie ułożyłeś — nie całe
zdanie, bo szuka po dosłownym fragmencie tytułu i opisu. Wynik obejmuje też
zadania zamknięte i cudze, byle mieściły się w zakresie widoczności właściciela
klucza.

Sam oceń, czy trafienie to naprawdę ta sama sprawa, czy tylko zbieżne słowa.
Gdy to samo — zamiast zwykłego bloku pokaż ostrzeżenie i czekaj:

```
Uwaga: w TMS jest już podobne zadanie

#1654  Poprawić filtr terminów na liście zadań
       TMS · W trakcie · Jan Kowalski

To samo? [pokaż mi je / zakładam mimo to / anuluj]
```

Przy zamkniętym trafieniu powiedz to wprost — „to samo zrobiono trzy tygodnie
temu" bywa ważniejsze niż otwarty bliźniak. Nigdy nie blokuj założenia: ostatnie
słowo ma człowiek, czasem podobne zadanie to celowo osobna sprawa.

## Formatowanie

`description` zadania i materiały do weryfikacji to **tekst formatowany** — ten sam
edytor, w którym ludzie piszą ręcznie w TMS. Wysyłaj HTML, nie goły tekst z `\n`:
łamania linii bez znaczników zlewają się w jedną ścianę.

Dozwolone znaczniki: `<p>` `<br>` `<strong>` `<em>` `<u>` `<s>` `<mark>` `<code>`
`<pre>` `<h1>`–`<h4>` `<ul>` `<ol>` `<li>` `<a href>` `<blockquote>` `<hr>`
`<table>` z `<tr>/<th>/<td>`. Reszta jest wycinana przy wyświetlaniu.

Lista do odhaczania — dokładnie w tym kształcie, inaczej TMS nie pokaże checkboxów:

```html
<ul data-type="taskList">
  <li data-checked="false" data-type="taskItem"><label><input type="checkbox"><span></span></label><div><p>Rozdzielić pakowanie zamówień powyżej pięciu pozycji</p></div></li>
  <li data-checked="true" data-type="taskItem"><label><input type="checkbox" checked="checked"><span></span></label><div><p>Zrobione już wcześniej</p></div></li>
</ul>
```

### Ile formatowania

Miarą jest to, czy jest co porządkować — nie to, czy da się użyć znacznika.

- Krótkie zadanie (dwa–trzy zdania) → same `<p>`. Nagłówek nad trzema zdaniami to
  hałas, nie struktura.
- Kilka wątków, ustalenia ze spotkania, wyliczenia → `<h3>` na sekcje i `<ul>` na
  punkty. Typowy podział: co ustalono, co do zrobienia, czego świadomie nie robimy.
- Punkty, które ktoś będzie odhaczał w trakcie roboty → lista zadań z checkboxami
  zamiast `<ul>`. Wszystkie zaczynają się odznaczone (`data-checked="false"`).
- Cytat z ustaleń albo warunek od kogoś z zewnątrz → `<blockquote>`.
- Nazwy plików, komendy, identyfikatory → `<code>`.

Nie używaj tabel do rzeczy, które są listą. Nie pogrubiaj całych zdań — `<strong>`
jest od wyróżnienia paru słów. Nie wstawiaj `<hr>` między akapitami tej samej myśli.

To samo dotyczy materiałów do weryfikacji: „Co zrobione" i „Jak sprawdzić" to
naturalne `<h3>`, a kroki weryfikacji — `<ol>`, bo mają kolejność.

## Propozycja

Po skończonej robocie: najpierw dwa–trzy zdania podsumowania prozą, potem blok:

```
Zadanie do TMS

Nazwa:      Poprawić filtr terminów na liście zadań
Opis:       Filtr „ten tydzień" gubi zadania z soboty i niedzieli.
            Zmiana w widoku listy, dotyczy wszystkich użytkowników.
            Do sprawdzenia też w widoku puli.

Projekt:    TMS
Pula:       Zadania / błędy
Wykonawca:  Jan Kowalski
Priorytet:  wysoki
Termin:     —

Założyć? [tak / popraw / anuluj]
```

Zasady składania:
- Nazwa: czasownik + rzecz, do 200 znaków, bez numerów zadań i żargonu z kodu.
- Opis: prozą, po ludzku — co jest do zrobienia i czego dotyczy. Bez nazw
  plików, funkcji i komend; to ma zrozumieć osoba, która nie siedziała w kodzie.
  W bloku pokazujesz go zwykłym tekstem, ale do TMS wysyłasz jako HTML — patrz
  „Formatowanie" wyżej. W bloku nie pokazujesz znaczników.
- Priorytet: `today` tylko gdy termin jest dzisiaj, `high` gdy blokuje kogoś
  lub psuje robotę na produkcji, inaczej `medium`. W bloku pokazujesz etykietę
  ze słownika, nie klucz — patrz „Priorytety" niżej.
- Projekt: z mapy `projectByFolder`, gdy katalog rozmowy do niej pasuje (patrz
  „Ustawienia"). Nie pytaj wtedy o projekt — pokaż go w bloku, człowiek poprawi
  przez „popraw", jeśli tym razem chodzi o co innego.
- Pola, których nie da się ustalić — myślnik. Nie wymyślaj puli ani terminu.
- Bez strzałek i uzasadnień przy polach. Dlaczego akurat ta osoba czy priorytet —
  tłumacz dopiero na pytanie.

Czekasz na odpowiedź. `popraw` → nanieś zmianę i pokaż blok jeszcze raz.
`anuluj` → nic nie zakładasz, temat zamknięty. Nie zakładaj bez wyraźnego „tak".

## Założenie

Treść idzie z pliku (patrz „Treść ZAWSZE z pliku") — tak samo w każdym przykładzie
niżej, gdzie widzisz `--data-binary`:

```bash
cat > zadanie.json << 'JSON'
{"title":"Poprawić eksport zamówień","description":"<p>Co i dlaczego.</p>","priority":"high","projectName":"TMS ✅","poolName":"Zadania / błędy","assigneeName":"Jan Kowalski"}
JSON
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  -H "Idempotency-Key: claude-eksport-zamowien-20260904" \
  --data-binary @zadanie.json \
  "$BASE/api/v1/integrations/inbound/claude"
```

Pola: `title`, `description`, `priority` (`today` | `high` | `medium` | `low` |
`do_not_touch`), `dueDate` (`YYYY-MM-DD`), `projectName`, `poolName`,
`assigneeName`. Nazwy podawaj dokładnie tak, jak przyszły ze słownika.

**Nagłówek `Idempotency-Key` dawaj zawsze**, z wartością własną dla tego jednego
zakładania — cokolwiek nie powtórzy się przy następnym. Gdy połączenie zerwie się
po tym, jak serwer już przyjął, ponowienie z tym samym nagłówkiem oddaje `200`,
`created: false` i numer zadania, które już stoi, zamiast zakładać bliźniaka.

**Why:** sekcja „Duplikaty" pilnuje duplikatów **ludzkich** — tego, że dwie osoby
zgłaszają to samo. Na duplikat **sieciowy** nie ma tam nic, a curl na Windowsie
potrafi wyjść timeoutem długo po tym, jak zadanie powstało.

Odpowiedź niesie `taskId`, `created` i **całe założone zadanie**:

```json
{"data":{"taskId":123,"created":true,"task":{"id":123,"title":"…","priority":"high",
         "priorityLabel":"Wysoki","reviewers":[{"id":27,"name":"Daniel Skrahlenko"}],
         "canSelfComplete":false}}}
```

Czytaj z niej dwie rzeczy, zanim cokolwiek zameldujesz:

- **jak zapisał się tytuł** — `task.title` to jedyne miejsce, w którym sprawdzisz,
  czy ogonki doszły całe (patrz „Treść ZAWSZE z pliku"),
- **`reviewers` i `canSelfComplete`** — potrzebne później do pytania o oddanie.
  **Nie dopytuj o nie osobnym odczytem**, skoro właśnie przyszły.

Zgłoś numer i link `$BASE/tasks/123` — jednym zdaniem, żeby dało się od razu
zajrzeć i poprawić na miejscu.

### Zadanie do puli, czyli niczyje

„Załóż zadanie w OMS, ktoś to weźmie", „wrzuć do puli" — **pominięcie
`assigneeName` NIE robi zadania niczyim**. TMS podpisuje wtedy właściciela klucza,
tak samo jakby poprosił o zadanie dla siebie. Zadanie wygląda na wzięte, choć nikt
go nie wziął, a Ty meldujesz sukces.

Niczyje robi się drugim ruchem — oddaniem do puli, jak przyciskiem „Oddaj"
w oknie zadania:

```bash
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  -d '{"unassign":true}' \
  "$BASE/api/v1/integrations/tasks/123/fields"
```

Zrób oba kroki po kolei i powiedz o tym jednym zdaniem — dla człowieka to jedna
czynność („założone i leży w puli, bez wykonawcy"). Gdy oddanie odbije się odmową,
powiedz wprost, że zadanie **zostało podpisane na Ciebie**; milczenie zostawiłoby
je przypisane wbrew temu, o co prosił.

Gdy zadanie powstało z roboty właśnie skończonej w tej rozmowie, nie kończysz na
numerze — przechodzisz od razu do „Materiałów do weryfikacji" niżej.

Gdy zadanie rozkłada się na kilka wyraźnych kroków, dopisz je jako punkty
checklisty (patrz „Podzadania") zamiast wyliczać w opisie — postęp widać wtedy
na liście zadań.

Kiedy coś nie wyjdzie:
- `401` — klucz odwołany albo zły. Powiedz to i odeślij do Ustawień w TMS.
- `403` — właściciel klucza nie jest członkiem tego projektu. Powiedz który
  projekt i zaproponuj inny ze słownika.
- `400` z informacją o niejednoznacznej nazwie — pokaż pasujące pozycje ze
  słownika i zapytaj, o którą chodzi.

Nie ponawiaj po błędzie w kółko i nie obchodź go innym polem. Powiedz, co się
stało, i zapytaj.

## Poprawa opisu

Opis istniejącego zadania poprawiasz **tylko na wyraźną prośbę** („popraw opis
1766", „sformatuj to zadanie") — nigdy z własnej inicjatywy, bo to cudza treść.

```bash
cat > opis.json << 'JSON'
{"html":"<p>Nowa treść opisu.</p>"}
JSON
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  --data-binary @opis.json \
  "$BASE/api/v1/integrations/tasks/1766/description"
```

W pliku jeden klucz: **`html`** — nie `description`, to odbija się `400`.

Zapis nadpisuje cały opis, więc **najpierw go przeczytaj** — zadanie wraca
z wyszukiwania bez treści opisu, więc poproś człowieka o wklejenie jej albo
odczytaj z rozmowy, jeśli to Ty ją pisałeś. Nie zgaduj, co tam było.

Przy samym formatowaniu (bez zmiany treści) trzymaj się reguły: **zmienia się
struktura, nie słowa**. Nagłówki, listy, pogrubienia — tak. Skracanie,
przestawianie zdań, poprawianie stylu — nie, chyba że człowiek o to poprosi.
Przed wysłaniem pokaż, co się zmieni.

Odmowy:
- `403 forbidden` — opis to domena zlecającego. Właściciel klucza może poprawiać
  opisy zadań, które sam założył (albo dowolne, gdy jest managerem lub liderem
  z uprawnieniem). Wykonawca cudzego zadania — nie; jego domeną są materiały do
  weryfikacji. Powiedz to wprost i zaproponuj materiały.
- `409 project_done` — projekt zakończony, zadanie tylko do odczytu.
- `404` — zadania nie ma albo jest poza jego zasięgiem.

## Nazwa, priorytet, termin, wykonawca i recenzenci

„Przesuń 1827 na piątek", „zleć to Wojtkowi", „oddaję to z powrotem do puli",
„niech sprawdzi to Daniel", „popraw nazwę na …" — jedno wejście, bo w TMS to
jedno okno edycji:

```bash
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  -d '{"dueDate":"2026-09-04"}' \
  "$BASE/api/v1/integrations/tasks/1827/fields"
```

Do wyboru, po jednym na raz albo razem:
- `title` — nowa nazwa zadania (3–200 znaków),
- `priority` — `today` | `high` | `medium` | `low` | `do_not_touch`,
- `dueDate` — `"2026-09-04"` ustawia termin, `null` go zdejmuje,
- `assigneeUserId` — numer osoby ZE SŁOWNIKA (nie imię),
- `unassign: true` — oddanie zadania do puli, czyli zdjęcie siebie,
- `reviewerUserIds` — kto ma sprawdzić robotę; numery osób ZE SŁOWNIKA, **cały
  skład naraz** (patrz „Recenzenci").

### Recenzenci

Recenzent ocenia oddaną robotę — to do niego trafia zadanie po „do weryfikacji".
Kto nim jest, mówi `reviewers` z odczytu zadania (`?taskId=`), imieniem i numerem.
Pusta lista znaczy, że zadanie wróci do zlecającego.

`reviewerUserIds` **podmienia całą listę, nie dopisuje do niej**. Dopisanie kogoś
zaczyna się więc od odczytu: bierzesz obecny skład, dokładasz nowego i wysyłasz
razem. Sam nowy numer zdejmuje wszystkich pozostałych — po cichu, bez ostrzeżenia.

```bash
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  -d '{"reviewerUserIds":[9,27]}' \
  "$BASE/api/v1/integrations/tasks/1721/fields"
```

**Pokaż skład przed i po, i poczekaj na „tak".** Recenzent dostaje powiadomienie,
a zadanie ląduje na jego liście do sprawdzenia:

```
#1721  sprawdza:      Piotr Stodółka
       ma sprawdzać:  Piotr Stodółka, Daniel Skrahlenko

Zmieniam? [tak / popraw / anuluj]
```

Recenzentem może być wyłącznie ktoś z projektu, w którym leży zadanie — kandydatów
szukaj wśród `owners` i `managers` tego projektu w słowniku, nie wśród wszystkich
`users`.

### Priorytety

**Klucz wysyłasz, etykietę mówisz — i etykiety nie bierzesz z pamięci.** Kluczy
jest pięć i one się nie zmieniają: `today`, `high`, `medium`, `low`,
`do_not_touch`. Nazwy widoczne dla ludzi bywają w TMS przemianowywane, więc
**czytasz je ze słownika** (`priorities`) i tak samo je wypisujesz — w bloku
propozycji, w pytaniu i w meldunku. Nazwa wpisana z pamięci rozjeżdża się z tym,
co człowiek widzi u siebie na ekranie.

„Podnieś 1827 na pilne" to `today`. „To już nie jest pilne" — zwykle `medium`,
ale przy tak luźnym zdaniu upewnij się, na co ma zejść, zamiast wybierać za
człowieka.

`do_not_touch` stoi **poza skalą** — nie jest najniższym stopniem po `low`.
Znaczy „tego nie ruszamy", cokolwiek akurat głosi jego etykieta. Nie proponuj go
jako kolejnego kroku w dół; ustawiasz go wtedy, gdy człowiek powie to wprost.

**Priorytet wraca z każdego odczytu** — jako `priority` (klucz) i `priorityLabel`
(etykieta), tą samą parą co `status` i `statusLabel`. Dostajesz go z wyszukiwania,
z `taskId`, z widoków i z listy puli. Zapis też jest sprawdzalny: `fields` oddaje
całe zadanie, więc nową wartość widzisz w odpowiedzi.

Skoro widzisz pilność, **używaj jej** — układaj listy od najpilniejszych i mów
wprost, co pilne. Etykietę cytuj tę, która przyszła w `priorityLabel`, nie tę
z pamięci.

Nazwa to treść pisana dla ludzi, więc idzie z pliku (patrz „Treść ZAWSZE z pliku"):

```bash
cat > nazwa.json << 'JSON'
{"title":"Poprawić eksport zamówień do BaseLinkera"}
JSON
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  --data-binary @nazwa.json "$BASE/api/v1/integrations/tasks/1827/fields"
```

Sam termin czy wykonawca (bez nazwy) mogą iść wprost — to wartości techniczne.

**Nową nazwę pokaż, zanim wyślesz** — obok starej, bo zmiana tytułu jest widoczna
dla wszystkich i nie zostawia po sobie śladu, czym była wcześniej:

```
#1827  było: Poprawić eksport
       ma być: Poprawić eksport zamówień do BaseLinkera

Zmieniam? [tak / popraw / anuluj]
```

Sam z siebie nazw nie poprawiaj — nawet gdy widzisz literówkę albo tytuł niezgodny
z tym, co ostatecznie weszło. Powiedz o tym i zaproponuj.

**Datę zawsze pokaż jako konkretny dzień, zanim wyślesz.** „Piątek" bywa nie tym
piątkiem, o którym myślisz — dzień tygodnia z datą rozwiewa to od razu: „termin na
piątek 4 września?".

**Przepisanie zadania komuś innemu potwierdź.** Tamta osoba zobaczy je u siebie
i dostanie powiadomienie. Oddanie do puli i własny termin — bez ceregieli, to
odwracalne.

Odmowy:
- `403 forbidden` — nazwę, priorytet, termin, wykonawcę i recenzentów zmienia ten,
  kto zlecił (albo lider czy manager). Jesteś tylko wykonawcą cudzego zadania? Możesz
  je oddać do puli, ale nie przestawić terminu, nazwy ani recenzenta — powiedz to
  i zaproponuj komentarz z prośbą.
- `403 assign_to_others_denied` — właściciel klucza nie ma prawa zlecać innym
  (`canAssignToOthers` w słowniku na `false`). Sprawdź to ZANIM zaproponujesz
  przepisanie, nie po odmowie.
- `400 reviewer_not_project_member` — wskazana osoba nie należy do projektu, w którym
  leży zadanie. Nie da się tego obejść wpisaniem kogoś podobnego: pokaż `owners`
  i `managers` tego projektu ze słownika i zapytaj, kto z nich ma sprawdzać.
- `409 project_done` — projekt zakończony, zadanie tylko do odczytu.
- `400` — sprzeczne wejście (naraz wykonawca i oddanie do puli), puste, nazwa
  krótsza niż trzy znaki albo priorytet spoza listy.

Projektu ani puli tędy nie zmieniasz — przeniesienie zdejmuje zadanie z jednej
tablicy i wiesza na drugiej, więc robi się to w TMS, patrząc na obie.

## Co do mnie przyszło

„Co mam do zrobienia", „co czeka na moją ocenę", „co oddałem", „co komu zleciłem" —
to pytania o WŁASNE sprawy, nie o tablicę projektu. Do tego służy `view`:

```bash
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/tasks?view=mine_active&limit=100"
```

Widoki i pytania, na które odpowiadają:
- `mine_active` — „co mam do zrobienia", moje niezakończone.
- `mine_done` — „co zrobiłem". Pytanie o konkretny okres („co dziś zrobione",
  „podsumuj mi tydzień") obsługuje skill `raport`, nie ten widok.
- `to_verify` — „co czeka na MOJĄ ocenę", cudza robota oddana do sprawdzenia.
- `awaiting` — „co oddałem i wisi" u kogoś do zatwierdzenia.
- `delegated` — „co zleciłem innym".

Zadanie z `unopened` na `true` jest świeże: zlecone właścicielowi klucza i jeszcze
przez niego nieotwierane w TMS. To najbliższe temu, co człowiek nazywa „nowe u mnie",
więc wypisz takie osobno albo oznacz — ale nie rób z tego alarmu.

```
Masz 5 zadań w toku, 2 jeszcze nieotwierane:

Nowe    #1841 Poprawić eksport faktur (zlecił Wojtek)
        #1839 Zdjęcia do karty produktu (zlecił Kuba)
W toku  #1833, #1827, #1791
```

Nie ma tu widoku puli — „pula" w TMS znaczy co innego niż w rozmowie. Zadania
czekające w puli projektu czytasz przez `poolId` (patrz niżej).

## Stan projektu i puli

Pytanie „co zostało w OMS", „co wisi w puli Fixy", „na czym stanęliśmy" to pytanie
o tablicę, nie o jedno zadanie. Numery projektów i pul masz w słowniku — użyj ich:

```bash
curl -s -H "Authorization: Bearer $KLUCZ"   "$BASE/api/v1/integrations/tasks?projectId=7&status=not_started,in_progress,waiting&limit=100"
```

Do wyboru `projectId`, `poolId` (sama pula wystarczy — należy do jednego projektu),
`status` (kilka po przecinku), `limit` (do 300) i `offset`. Bez `status` wracają
wszystkie, także zakończone — to właśnie odpowiedź na „co zrobione, a co czeka".

Odpowiedź niesie obok `tasks` blok `page` — i to z niego czytasz, ile tego jest:

```json
"page": { "total": 359, "limit": 300, "offset": 0, "hasMore": true, "capped": false }
```

`total` to liczba trafień, `hasMore` mówi, czy za tą stroną coś jeszcze jest,
a `capped` na `true` znaczy, że zapytanie dobiło do stropu i sam `total` jest
ucięty — jedyny przypadek, w którym uczciwą odpowiedzią jest „nie wiem, ile tego
jest". Nie wnioskuj o kompletności z tego, czy wynik dobił do `limit`: projekt
z 359 zadaniami przy `limit=300` wygląda wtedy identycznie jak ucięty, a nie jest.

W tym widoku są też **zadania bez wykonawcy** — czyli to, co dopiero czeka na
podjęcie. Przy zwykłym wyszukiwaniu po słowach ich nie ma.

Każde zadanie niesie `status`, `statusLabel`, `priority`, `priorityLabel`,
`assignees`, `poolName` i `dueDate`. Odpowiadaj stanem tablicy, nie surową listą:

```
Projekt OMS — 14 zadań

Zrobione       8
W trakcie      2   #61 śledzenie przesyłek (Piotr), #58 raport dzienny (Wojtek)
Odstawione     1   #57 integracja z kurierem (Piotr) — status „Czeka"
Nierozpoczęte  3   w tym 2 bez wykonawcy
```

Status `waiting` („Czeka") to zadanie **odstawione** — ktoś je już miał i wstrzymał.
To co innego niż `not_started`, które po prostu nie ruszyło. Nie zlepiaj obu
w jedną kupkę „czeka" i nie podsuwaj odstawionych, gdy ktoś pyta „co następne" —
one stoją z powodu, którego lista nie pokazuje.

Przy zestawieniu takim jak wyżej linki wypisz pod spodem, po jednym na zadanie —
w tabelce rozwaliłyby układ, ale zniknąć nie mogą.

Gdy człowiek pyta „co następne", pokaż same czekające i zaproponuj jedno — nie
wyliczaj wszystkiego. Kolejność bierzesz z priorytetu, terminu i blokad; przy
wyborze powiedz, czym się kierowałeś. Pusty wynik znaczy tyle, że w JEGO zasięgu
widoczności nic tam nie ma; nie dopowiadaj, czy zadania nie ma, czy tylko go nie
widzi.

**Stan czytasz z TMS, nie z pliku w repozytorium.** Tablica w `BOARD.md` czy innym
pliku bywa nieaktualna i nie jest drugim źródłem prawdy — jeśli rozjeżdża się z TMS,
powiedz to, ale nie synchronizuj jej sam.

## Rozdanie niczyich zadań

„Rozdziel niczyje z OMS między mnie, Wojtka i Daniela", „kto co bierze z tej puli" —
gdy nad projektem siedzi kilka osób, a część zadań nie ma wykonawcy.

**Osoby bierzesz z rozmowy, nie z projektu.** Nie zgaduj, kto akurat pracuje nad
tematem — padły trzy imiona, dzielisz między te trzy. Nikogo nie dokładasz od siebie.
Imiona zamień na numery ze słownika; kogoś, kogo tam nie ma, zgłoś zamiast pomijać
po cichu.

Zacznij od jednego zapytania — z blokadami, bo bez nich podzieliłbyś na ślepo:

```bash
curl -s -H "Authorization: Bearer $KLUCZ" \
  "$BASE/api/v1/integrations/tasks?projectId=7&status=not_started&withBlockers=1&limit=100"
```

`withBlockers=1` dokłada przy każdym zadaniu `blockedBy` — numery zadań, na które
ono czeka. **Niczyje poznajesz po pustym `assignees`.**

Jak dzielić, po kolei:

1. **Łańcuch blokad trzymaj w całości.** Zadanie i to, na co czeka, idą do JEDNEJ
   osoby. Rozbite między dwie znaczy, że ktoś siedzi bezczynnie, czekając na kolegę
   przy własnej robocie. Łańcuch bywa dłuższy niż para — idź po `blockedBy`, dopóki
   prowadzi dalej. Gdy bloker ma już wykonawcę, resztę łańcucha dawaj właśnie jemu.
2. **Potem trzymaj razem jedną pulę.** Zadania z tej samej puli do tej samej osoby —
   mniej przeskakiwania między tematami. To reguła słabsza od blokad: gdy się kłócą,
   wygrywa łańcuch.
3. **Resztę rozłóż równo co do liczby.** Nie patrzysz, kto ile ma już na głowie —
   tego nie liczysz i nie udawaj, że wiesz.

**Pokaż CAŁY podział i czekaj na „tak".** Jedno pytanie o wszystko, nie osobne
o każde zadanie:

```
Niczyje w OMS: 7 zadań, 3 osoby

Piotr    #1812 Eksport do BaseLinkera
         #1815 Testy eksportu          ← czeka na #1812
Wojtek   #1820, #1821  (oba z puli „11 — Obsługa klienta")
Daniel   #1808, #1809, #1810  (pula „0 - fixy")

#1815 idzie z #1812, bo bez niego nie ruszy.

Rozdzielam? [tak / popraw / anuluj]
```

Przy każdej grupie dopisz **powód jednym zdaniem** tam, gdzie nie jest oczywisty —
łańcuch blokad zawsze, wspólna pula gdy to ona zdecydowała. Linki do zadań pod spodem,
jak przy zestawieniach.

Po „tak" przypisujesz po kolei (`assigneeUserId`, patrz „Nazwa, priorytet, termin, wykonawca i recenzenci")
i meldujesz jednym zdaniem, co komu przypadło. Odmowa na którymś zadaniu nie
przerywa reszty — dokończ i powiedz na końcu, co nie weszło i dlaczego.

Czego NIE robisz:
- nie rozdajesz bez potwierdzenia — każde przypisanie to powiadomienie u żywej osoby,
- nie ruszasz zadań, które KTOŚ już ma; rozdajesz wyłącznie niczyje,
- nie zgadujesz obciążenia („Wojtek ma dużo roboty") — nie masz tego skąd wiedzieć,
- przy `canAssignToOthers` na `false` mówisz to od razu, ZANIM ułożysz podział;
  wtedy jedyne, co możesz, to wziąć zadania na siebie.

## Treść zadania: opis, zdjęcia, załączniki

Wyszukiwanie daje tytuł, status i wykonawców — nie treść. Po opis sięgasz osobno:

```bash
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/tasks/1721/description"
```

Wraca `{taskId, title, html, imagesInDescription, images}`. `html` to opis tak, jak
trzyma go edytor, a `images` to zdjęcia w nim wklejone — każde z `name` i `path`.

**Tytuł jest treścią, nie etykietą** — czytasz go zawsze razem z opisem. Tytuł mieści
całe polecenie i część zadań ma je właśnie tam, a opis zostaje pusty z założenia:
„Możliwość oznaczania załączników przez @@" to komplet — jest czasownik, przedmiot
i sposób. Puste `html` (`null`) nie znaczy więc „brak treści zadania". Najpierw
sprawdź, czy tytuł sam nie jest pełnym poleceniem: gdy jest — pracujesz na nim
i nie prosisz o opis. Dopytujesz dopiero wtedy, gdy ani tytuł, ani punkty checklisty
nie mówią, co zrobić.

Zdjęcie wklejone do edytora **nie jest załącznikiem zadania**: nie ma go na liście
załączników i nie szukaj go tam. Pobierasz je ścieżką z `path` (doklej `$BASE`):

```bash
curl -s -H "Authorization: Bearer $KLUCZ" -o zrzut.png \
  "$BASE/api/v1/integrations/tasks/1503/images/a7e1a5c1-....png"
```

Potem otwierasz plik jak każdy inny — patrz „Zawartość" niżej. Adres z samego `html`
(`/api/v1/editor-images/…`) tędy nie zadziała, bo chce sesji przeglądarki; bierz `path`.

Co doczepione:

```bash
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/tasks/1721/attachments"
```

Lista `{id, fileName, mimeType, sizeBytes, kind, uploadedByName, uploadedAt, readable}`.
`kind` to `task` (kontekst zadania: brief, instrukcja) albo `verification` (dowód
pracy) — zawęzisz przez `?kind=task`. `readable: false` znaczy, że plik przekracza limit
25 MB; powiedz to zamiast próbować go ściągać.

Zawartość — **zapisz do pliku i otwórz go**:

```bash
curl -s -H "Authorization: Bearer $KLUCZ" -o zrzut.png \
  "$BASE/api/v1/integrations/task-attachments/45"
```

Potem czytasz plik zwykłym narzędziem do odczytu. Obrazy widzisz naprawdę — co jest
zaznaczone strzałką, jaki komunikat błędu jest na zrzucie, co pokazuje wykres. Tak samo
PDF-y, pliki tekstowe, CSV, logi i kod.

Kiedy po to sięgasz:
- **zadanie mówi „jak na zrzucie"** — obejrzyj zrzut, zamiast pytać, co na nim jest,
- **człowiek prosi wprost** („co jest na tym zdjęciu w 1721", „przeczytaj załącznik"),
- **bierzesz się za zadanie**, a opis ma obrazy albo pliki — zajrzyj, zanim zaczniesz.
  Przy tej samej okazji pobierz checklistę (patrz „Podzadania"): opis mówi, po co
  zadanie powstało, a punkty — co do niego naprawdę należy.

Nie pobieraj wszystkiego hurtem „na wszelki wypadek". Bierz to, co potrzebne do roboty,
o którą chodzi — każdy plik to koszt i czas.

Czego nie otworzysz wprost: **Worda i Excela**. Powiedz to po ludzku („to plik Excela,
nie odczytam go stąd") i zapytaj, czy człowiek nie woli wkleić tego, co istotne.

Odmowy:
- `404` — zadania albo pliku nie ma, lub są poza zasięgiem właściciela klucza. Numer
  załącznika sprawdzamy przez zadanie, do którego należy, więc cudzy plik też da `404`.
- `413 file_too_large` — plik ponad 25 MB. Nie próbuj obejść.
- `400 invalid_kind` — dozwolone są tylko `task` i `verification`.

### Wysłanie pliku

Plik Z DYSKU — log, zrzut z testu, wygenerowany raport — dokładasz do zadania:

```bash
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" \
  -F "file=@/sciezka/do/log.txt" -F "kind=verification" \
  "$BASE/api/v1/integrations/tasks/1721/attachments"
```

`kind=verification` (domyślne) to materiały do weryfikacji — dowód skończonej
roboty; wgrywa je wykonawca. `kind=task` to kontekst zadania, brief czy instrukcja —
wgrywa go ten, kto zadanie zlecił. Nie odwracaj tego: dowód pracy w załącznikach
zadania wygląda, jakby ktoś dołożył wymagania.

**Powiedz, co wysyłasz i dokąd, zanim wyślesz.** Plik zostaje przy zadaniu na stałe
i widzą go wszyscy — to nie jest ruch odwracalny po cichu.

**Czego nie wyślesz:** zrzutu wklejonego do okna rozmowy. Dla Ciebie to obraz
w kontekście, nie plik na dysku — nie ma czego przekazać dalej. Powiedz to wprost
i poproś o zapisanie go na dysku albo o ścieżkę; nie udawaj, że się nie udało
z innego powodu, i nie próbuj odtwarzać obrazka.

Odmowy:
- `403 forbidden` — nie ta sekcja dla tej osoby (patrz podział wyżej).
- `413` — plik albo cała sekcja przekracza limit. Serwer podaje, ile zajęte
  i ile zostało — powtórz to człowiekowi zamiast samego „za duży".
- `409 project_done` — projekt zakończony, zadanie tylko do odczytu.

## Komentarze

Komentarze są w TMS główną rozmową o zadaniu. Opis mówi, co było do zrobienia na
starcie; co ustalono po drodze — mówią komentarze. Czytaj je zawsze, gdy masz
zrozumieć stan sprawy, a nie tylko zobaczyć tytuł.

```bash
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/tasks/1721/comments"
```

Wracają `total` i ostatnie wpisy (domyślnie 30, `limit` do 100), od najstarszego:
`author`, `createdAt`, `html`, `replyToAuthor`, `images`. Gdy `total` jest większe niż
to, co dostałeś, powiedz o tym — „ostatnie 30 z 54" — zamiast udawać, że widziałeś całość.

`images` to zdjęcia wklejone do komentarza, pobierane tak samo jak te z opisu. Zrzut
w komentarzu zwykle NIESIE sedno („o, tu się sypie") — obejrzyj go, zanim streścisz wątek.

Streszczaj, nie przepisuj. Człowiek pyta „co tam ustalili", nie „przeczytaj mi wątek".

### Dopisanie komentarza

```bash
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  --data-binary @komentarz.json \
  "$BASE/api/v1/integrations/tasks/1721/comments"
```

Treść formatujesz tak jak opis (patrz „Formatowanie"). Odpowiedź na czyjś wpis —
dołóż `replyToId` z odczytu.

**Każdy komentarz pisany Twoją ręką kończy się podpisem** — osobnym akapitem na
samym dole treści, także w odpowiedzi na czyjś wpis:

```html
<p>🤖 <em>napisane przez Claude'a</em></p>
```

Klucz jest osobisty, więc wpis i tak firmuje w TMS jego właściciel. Podpis mówi
czytającemu, że zdania układał model, a nie człowiek — bez tego wątek wygląda tak,
jakby wszystko napisali ludzie. Do opisu ani do materiałów go nie dopisujesz: tam
stoi robota, a nie rozmowa.

**Pokaż treść i poczekaj na „tak".** Komentarz widzą wszyscy przy zadaniu i idzie
z niego powiadomienie — to nie jest ruch odwracalny po cichu, jak start zadania.

Komentujesz pod każdym zadaniem, które właściciel klucza widzi, także cudzym —
to jego prawo w TMS. Nie mylą się za to trzy rzeczy, każda ma swoje miejsce:
- **opis** — co jest do zrobienia; domena zlecającego,
- **materiały do weryfikacji** — co zrobiono i jak to sprawdzić; domena wykonawcy,
- **komentarz** — rozmowa, pytanie, ustalenie; każdego, kto widzi zadanie.

Gdy człowiek mówi „dopisz, że…", zwykle chodzi o komentarz. Gdy mówi „opisz, co
zrobiłeś" przy własnym zadaniu — o materiały. W razie wątpliwości zapytaj, zamiast
wpisywać ustalenie z rozmowy do opisu cudzego zadania.

Komentarzy nie poprawiasz i nie kasujesz — także własnych. Porządki w wątku robi
się w TMS, gdzie widać kontekst.

Odmowy: `404` — zadania nie ma albo jest poza zasięgiem właściciela klucza.

## Zgłoszenia błędów

Część zadań powstaje ze **zgłoszeń** — ktoś zgłosił błąd, ktoś zrobił z tego zadanie.
Zgłoszenie żyje wtedy własnym życiem: ma swój status i swojego autora, który czeka na
odpowiedź. Zamknięcie zadania samo z siebie NIC z nim nie robi.

```bash
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/tasks/1721/bug-reports"
```

Pusta lista = zadanie nie powstało ze zgłoszenia; nie drąż. Lista bywa dłuższa niż
jednoelementowa — ten sam błąd zgłasza czasem kilka osób i wszystkie te zgłoszenia
wskazują jedno zadanie. Każde niesie `status`, `statusLabel`, autora i `canManage`.

### Kiedy proponować zmianę statusu

- **Start zadania**, a zgłoszenie ma `nowe` → zaproponuj „w trakcie". Autor zgłoszenia
  widzi wtedy, że ktoś się tym zajął.
- **Zamknięcie albo oddanie do weryfikacji** → zaproponuj „rozwiązane".

```bash
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  -d '{"status":"rozwiazane"}' \
  "$BASE/api/v1/integrations/bug-reports/12"
```

**Zawsze pytaj, nigdy sam.** Domknięcie zgłoszenia wysyła powiadomienie do osoby,
która je zgłosiła — inaczej niż start zadania, to nie jest ruch po cichu. Przy kilku
zgłoszeniach naraz zapytaj o wszystkie jednym pytaniem, nie po kolei.

`canManage` na `false` → powiedz, że statusami zgłoszeń zarządza ten, kto je
rozpatruje, i **nie próbuj**. Zadanie idzie swoim torem, zgłoszenie zostaje.

Uzasadnienia nie dopisuj z własnej inicjatywy. Puste zostawia notatkę, którą
rozpatrujący wpisał wcześniej w module; wysłane — nadpisuje ją.

### Odrzucenie i duplikat

Na wyraźną prośbę: `{"status":"odrzucone","resolutionNote":"..."}` — tu uzasadnienie
jest na miejscu, bo autor zgłoszenia dowie się, dlaczego. Duplikat wymaga wskazania
zgłoszenia głównego: `{"status":"duplikat","duplicateOfId":8}`. Numer znajdź, zamiast
zgadywać:

```bash
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/bug-reports?status=nowe"
```

Sam z siebie nie proponuj ani odrzucenia, ani duplikatu — obie decyzje wymagają
porównania z resztą zgłoszeń, a Ty widzisz tylko wycinek.

### Powiązanie ze zgłoszeniem

Zadanie da się przypiąć do zgłoszenia (i odpiąć):

```bash
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  -d '{"taskId":1841}' \
  "$BASE/api/v1/integrations/bug-reports/12"
```

`{"taskId":null}` odpina. Przydaje się, gdy zadanie powstało z rozmowy, a dopiero
potem okazało się, że dotyczy zgłoszonego błędu. Zgłoszenia bez zadania znajdziesz
przez `?unlinked=1`.

Pokaż jedno i drugie — zgłoszenie i zadanie — i zapytaj, zanim zwiążesz. Powiązanie
stempluje zadanie jako pochodzące ze zgłoszenia, więc widać je potem w TMS.

Status i powiązanie to dwie osobne decyzje: nie załatwiaj obu jednym pytaniem.

## Blokady

Zadanie potrafi czekać na inne — przez punkt checklisty z przypiętym cudzym
zadaniem. Checklista mówi tylko `blocked: true`; czym jest blokada, mówi to:

```bash
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/tasks/1721/blockers"
```

Wracają obie strony: `waitingOn` (na co czeka to zadanie — `subtaskText`, `taskId`,
`title`, `statusLabel`, `assignees`, `done`) i `blocking` (kogo samo wstrzymuje).

Sięgasz po to, gdy:
- punkt checklisty ma `blocked: true` i trzeba powiedzieć, na co czeka,
- oddanie odbiło się o `409 subtasks_pending`, a punkt jest zablokowany — wtedy
  nie ma czego odhaczać, jest na co czekać,
- człowiek pyta „czemu to stoi" albo „co odblokuje 1721".

Powiedz po ludzku, kto jest po drugiej stronie: „czeka na #1699 *Klucze integracyjne*
— w trakcie, u Wojtka", i dołóż link do tamtego zadania — to na nie ktoś będzie chciał
zajrzeć. Wpis z `done: true` to blokada już domknięta; punkt odhaczy
się sam, nie ma tam nic do zrobienia.

### Założenie blokady

„To czeka na 1827", „zablokuj ten punkt, dopóki Wojtek nie skończy" — blokada wisi
na PUNKCIE checklisty i wskazuje zadanie, na które ten punkt czeka. Nie ma punktu?
Najpierw go dopisz (patrz „Podzadania"), potem przypnij.

```bash
curl -s -w '\n%{http_code}' -X PUT \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  -d '{"blockerTaskId":1827}' \
  "$BASE/api/v1/integrations/tasks/1721/subtasks/45/blocker"
```

Zdjęcie — `DELETE` tej samej ścieżki, bez treści. Punkt wraca wtedy nieodhaczony,
nawet jeśli bloker był zamknięty: roboty nikt za niego nie zrobił.

Zanim przypniesz, ustal KTÓRE zadanie blokuje — po numerze albo wyszukaniem, jak przy
zmianie statusu. Pokaż oba zadania i zapytaj; przypięcie wysyła powiadomienie do
wykonawcy blokera, więc to nie jest ruch po cichu.

Punktu z blokadą nie odhaczysz ręcznie i nie próbuj — odhaczy się sam, gdy bloker
zostanie zamknięty. Nowego zadania-blokera wtyczka nie zakłada jednym ruchem: gdy
blokera jeszcze nie ma, załóż zadanie normalnie, z potwierdzeniem, i dopiero je przypnij.

Odmowy:
- `403 forbidden` — blokady stawia twórca zadania albo jego wykonawca. Przy samych
  punktach checklisty reguła jest szersza, więc „mogę dopisać punkt, ale nie mogę go
  zablokować" to normalna sytuacja, nie błąd.
- `409 cycle` — zadania zablokowałyby się nawzajem, choćby przez łańcuch pośredników.
  Powiedz, że tak się nie da, i pokaż, co już na co czeka.
- `404 blocker_not_found` — zadania-blokera nie ma albo właściciel klucza go nie widzi.
- `409 no_blocker` przy zdejmowaniu — na tym punkcie nic nie wisi.


## Historia zmian statusu

Status mówi, gdzie zadanie stoi **teraz**. Kto je tam postawił, kiedy i ile razy
wracało — mówi historia:

```bash
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/tasks/1721/work-history"
```

Wraca `entries`, od najstarszego wpisu: `at`, `from` i `to` (klucze statusów) razem
z `fromLabel` i `toLabel`, oraz `by` — imię osoby, która przestawiła. Pusta lista
znaczy, że zadania nikt jeszcze nie ruszył; to nie błąd. Etykiety cytuj te, które
przyszły — tak samo jak przy `statusLabel` w reszcie odczytów.

Kiedy po to sięgasz:
- **„na czym stanęliśmy", „ile razy to wracało", „kto to odstawił"** — jedno
  zadanie, nie tablica.
- **Zadanie wróciło „Do poprawy"** — sama liczba nawrotów mówi tyle, co treść
  uwag: pierwszy raz to normalna tura, trzeci to znak, że coś się nie dogaduje.
  Uwagi czytasz osobno (patrz „Odczyt materiałów i uwag do poprawy").
- **Bierzesz się za cudze zadanie** i chcesz wiedzieć, czy ktoś już przy nim był.

Na „czemu to stoi" odpowiadasz **jednym i drugim**: blokady mówią, na co zadanie
czeka, a historia — kto i kiedy je zatrzymał. Zadanie na „Czeka" bez blokad
odstawił człowiek, i to jego imię widać właśnie tutaj.

Streszczaj, nie przepisuj wierszy. „Wojtek oddał 4 września, wróciło do poprawy
tego samego dnia, od tamtej pory stoi" mówi więcej niż pięć linijek z datami.

Odmowy: `404` — zadania nie ma albo jest poza zasięgiem właściciela klucza.
Historię widzi każdy, kto widzi zadanie, więc odmowa znaczy, że zadania nie widać
w ogóle — nie że sama historia jest zamknięta.

## Zmiana statusu

Statusy w TMS: `not_started` (Nierozpoczęty), `in_progress` (W trakcie),
`waiting` (Czeka), `to_verify` (Do weryfikacji), `completed` (Zakończone),
`rework_needed` (Do poprawy).

Najpierw ustal, o które zadanie chodzi. Numer podany wprost → pobierz je po
`taskId`. Opis słowny („to o filtrach") → poszukaj przez `query` jak przy
duplikatach. Kilka trafień — pokaż listę i zapytaj. Zero trafień — powiedz to,
nie zgaduj.

```bash
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/tasks?taskId=1721"
```

Zadanie wraca z `status`, `canSelfComplete` i `canVerify`. Zmiana:

```bash
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  -d '{"status":"in_progress"}' \
  "$BASE/api/v1/integrations/tasks/1721/status"
```

Co z czym:
- „zaczynam", „biorę się za to" → `in_progress`. Bez pytania o zgodę — to
  odwracalne. Powiedz jednym zdaniem, które zadanie ruszyłeś, z linkiem.
  Zadanie z puli (bez wykonawcy) start bierze na właściciela klucza — tak jak
  „Weź" w oknie zadania. Powiedz to jednym zdaniem: wzięte i w toku. Zadania,
  które ma już wykonawcę, start nie przejmuje.
- „zrobione", „skończone" → `canSelfComplete` mówi tylko, czy zadanie ma nad sobą
  recenzenta — **nie to, czy serwer pozwoli je zamknąć**. `true` → proponuj
  `completed`. Przy `false` decyduje rola właściciela klucza w tym projekcie
  (`myRole` ze słownika):
  - **kierownik albo właściciel projektu** → obie drogi stoją otworem. Pokaż je
    jednym pytaniem, z imieniem recenzenta: `[zakończone / do weryfikacji]`.
    Kierownik zamykający własne zadanie nie ma po co chodzić po zgodę do drugiego
    kierownika, a wtyczka nie jest od pilnowania tego za TMS.
  - **uczestnik** → zadanie faktycznie czeka na czyjąś weryfikację; proponuj
    `to_verify` i powiedz, na kogo. Flagi tu nie obchodzisz i nie próbujesz
    „na wszelki wypadek".

  **Reguła w `rules`, która wybiera któreś z tych wyjść, znosi pytanie.** „Jako
  kierownik zamykam swoje zadania sam" decyduje już za człowieka — wysyłasz od razu
  i mówisz jednym zdaniem, co się stało i **z czego to wyszło**:

  ```
  Zamknięte — zgodnie z Twoją regułą „jako kierownik zamykam swoje zadania sam".
  Zmienisz ją w /tms:ustawienia.
  https://tms.firma.pl/tasks/1721
  ```

  Reguła musi trafiać w to konkretne rozwidlenie i w tę rolę — „zamykam swoje
  zadania" nie mówi nic o zadaniu cudzym ani o tym, komu je oddać. **Nie
  naciągasz**: reguła połowiczna albo nie o tym → pytasz normalnie.

  Bez takiej reguły **czekaj na „tak"**, dopiero potem wysyłaj.

  **Why:** `canSelfComplete` liczy się z samej obecności recenzenta i nie patrzy,
  kim wykonawca jest w projekcie. Zmierzone 2026-09-03: zadanie z `canSelfComplete`
  na `false` i recenzentem, którego wykonawca jest kierownikiem tego samego
  projektu, serwer zamyka bez mrugnięcia — `200`, `status: completed`. Wtyczka
  czytała tę flagę jak zakaz i odsyłała kierownika po zgodę do drugiego kierownika.
- „to stoi", „czekam na Wojtka", „odstawiam to na potem" → `waiting`. Bez pytania
  o zgodę, to odwracalne. Powiedz, że zadanie odstawione i **na co czeka** —
  sam status tego nie niesie, a bez tego nikt nie wie, kiedy je wznowić.
- „wracam do tego", „już mogę robić" → **osobne wejście, bez podawania statusu**:

  ```bash
  curl -s -w '\n%{http_code}' -X POST \
    -H "Authorization: Bearer $KLUCZ" \
    "$BASE/api/v1/integrations/tasks/1721/resume"
  ```

  TMS sam wie, dokąd wrócić: zadanie odstawione w toku wraca w tok, odstawione
  przed rozpoczęciem — do nierozpoczętego. **Nie ustawiaj statusu ręcznie** i nie
  pytaj, na co wrócić — zgadywanie kończy się tym, że system twierdzi, że ktoś
  zaczął robotę, której nikt nie tknął. Powiedz potem, w jakim stanie zadanie
  wylądowało. `409 not_waiting` znaczy, że zadanie wcale nie stoi — sprawdź stan,
  zanim powiesz, że coś poszło nie tak.
- Zadanie w stanie `not_started` trzeba najpierw wystartować — TMS nie pozwoli
  oddać nierozpoczętego. Zrób oba kroki po kolei i wspomnij o tym jednym zdaniem,
  bo dla człowieka to jedna czynność.

Czekanie bywa też **postawione przez TMS, nie przez człowieka**: gdy każdy
nieodhaczony punkt checklisty ma blokadę, zadanie samo idzie na „Czeka" i samo
wraca, gdy blokada zniknie. Zadanie na „Czeka" z zablokowanymi punktami sprawdź
przez blokady (patrz wyżej) i powiedz, na co czeka — zamiast proponować, żeby
je ręcznie wznowić, bo automat odstawi je z powrotem.

Odmowy:
- `403 forbidden_transition` — uprawnienia nie dają tego przejścia. Najczęściej:
  zadanie zlecił ktoś inny, więc zamyka je on, nie wykonawca. Powiedz to po
  ludzku i zaproponuj oddanie do weryfikacji.
- `404` — zadania nie ma albo właściciel klucza go nie widzi. Nie drąż, o które
  chodziło; poproś o numer.
- `409 subtasks_pending` — zostały nieodhaczone punkty checklisty. Pokaż je
  (patrz „Podzadania") i zapytaj, czy odhaczyć. `409 not_published` — zadanie
  jeszcze nieodblokowane w serii. Powiedz, co blokuje.

Nie obchodź odmowy innym statusem i nie ponawiaj jej w kółko.

## Podzadania

Checklista wewnątrz zadania: krótkie punkty do odhaczenia. To nie są osobne
zadania — nie mają wykonawcy, statusu ani terminu, więc nie znajdziesz ich
wyszukiwaniem. Zawsze idziesz przez numer zadania.

Podgląd:

```bash
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/tasks/1721/subtasks"
```

Wraca lista `{id, text, description, done, blocked}`. `text` to sama treść punktu,
`description` — jego własne rozwinięcie, gdy zlecający coś przy nim dopisał. Czytasz
oba; w `description` siedzą warunki, których w jednej linijce nie dało się zmieścić.

Dopisanie punktów — całą listą naraz, nie po jednym:

```bash
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  --data-binary @punkty.json \
  "$BASE/api/v1/integrations/tasks/1721/subtasks"
```

Odhaczenie (`done: false` odznacza z powrotem):

```bash
curl -s -w '\n%{http_code}' -X PATCH \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  -d '{"done":true}' \
  "$BASE/api/v1/integrations/tasks/1721/subtasks/45"
```

Kiedy z tego korzystasz:
- **Bierzesz się za zadanie** — sprawdzasz checklistę, ZANIM cokolwiek zrobisz, tak
  samo jak czytasz opis. Nie pytasz o zgodę i nie czekasz, aż ktoś o niej wspomni;
  to jeden odczyt. Ma punkty — czytasz je wszystkie, `text` i `description`, razem
  z odhaczonymi: one mówią, co już zrobiono, więc oszczędzają robotę drugi raz.
  **Zakres zadania bardzo często stoi wyłącznie w punktach**, a opis niesie sam
  powód — zadanie zrobione po samym opisie bywa zrobione w połowie i widać to
  dopiero przy oddawaniu, gdy TMS odbija je przez `subtasks_pending`.
- **Zadanie z kilku wyraźnych kroków** — przy zakładaniu wpisz je jako punkty
  checklisty zamiast wyliczenia w opisie. Wtedy widać postęp na liście zadań.
  Opis zostaje na „po co i dlaczego", punkty niosą „co po kolei".
- **Odmowa `subtasks_pending`** — pobierz listę, pokaż nieodhaczone i zapytaj,
  czy odhaczyć. Nie odhaczaj sam pod pretekstem oddania zadania.
- **Człowiek mówi wprost** („odhacz drugi punkt", „co jeszcze zostało w 1766").

Punkt z `blocked: true` ma przypięte cudze zadanie — odhaczy się sam, gdy tamto
zostanie zamknięte. Ręcznie się nie da (`409 subtask_blocked`); powiedz, na co
czeka, zamiast próbować.

Odmowy:
- `404` — zadania nie ma, jest poza zasięgiem właściciela klucza, albo punkt nie
  należy do tego zadania.
- `403 forbidden` — zadanie widoczne, ale checklisty w nim nie ruszysz. Punkty
  dopisuje i odhacza twórca zadania, wykonawca, właściciel lub manager projektu.
- `409 project_done` / `409 task_archived` — zadanie tylko do odczytu.
- `409 limit_exceeded` — limit punktów na zadanie. Zaproponuj rozbicie na osobne
  zadania.

## Materiały do weryfikacji

Po założeniu zadania z właśnie skończonej roboty prowadzisz ciąg dalej **bez
pytania**: ustawiasz `in_progress`, zapisujesz materiały, i dopiero przed
oddaniem się zatrzymujesz.

```bash
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  --data-binary @materialy.json \
  "$BASE/api/v1/integrations/tasks/1721/materials"
```

Treść to prosty HTML: `<p>`, `<strong>`, `<ul><li>`. Bez nagłówków, tabel
i stylów. Dwie części, w tej kolejności:

1. **Co zrobione** — dwa–cztery zdania prozą: co się zmieniło i dlaczego.
2. **Jak sprawdzić** — lista kroków dla osoby weryfikującej: gdzie zajrzeć, co
   powinna zobaczyć, czego świadomie nie ruszaliśmy. Konkretnie — „wejdź w
   Ustawienia → Klucze i wydaj klucz, powinien pokazać się raz", nie „sprawdź
   czy działa".

Nazwy plików, funkcji i komend tylko wtedy, gdy weryfikujący bez nich nie ruszy.
Zwykle nie ruszy bez nich w zadaniach czysto technicznych — wtedy podaj, ale
resztę pisz po ludzku.

Po zapisie pokaż krótko, co wpisałeś, i link do zadania.

**Zanim zapytasz o oddanie, musisz mieć `canSelfComplete` i `reviewers`.** Gdy
zadanie założyłeś przed chwilą, **oba przyszły w odpowiedzi na założenie** — użyj
ich i nie pytaj serwera drugi raz o to samo. Odczytu potrzebujesz tylko wtedy, gdy
zadanie jest cudze albo starsze niż ta rozmowa:

```bash
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/tasks?taskId=1721"
```

Bez tych dwóch pól nie wiesz, czy zadanie ma w ogóle kogoś, kto je sprawdzi. `reviewers`
mówi to imiennie — **i tak właśnie o tym mów**: „pójdzie do Wojtka", nie „pójdzie
do weryfikacji". Zadanie własne z pustą listą recenzentów oddane „do weryfikacji"
ląduje na liście recenzji u tego, kto je zlecił — czyli u autora roboty. Kierownik
projektu tej listy nie widzi, więc zadanie utyka tam, gdzie nikt go nie szuka.
Zamiast oddawać w próżnię, zaproponuj wskazanie recenzenta (patrz „Recenzenci").

Samo zadanie nie mówi, kim jesteś w jego projekcie — **rolę bierzesz z `myRole`
w słowniku** i bez niej nie ułożysz pytania o oddanie (patrz „Zmiana statusu").

Osobno, na prośbę („dopisz materiały do 1654"): znajdź zadanie jak przy zmianie
statusu i zapisz. Działa na każdym zadaniu, w którym właściciel klucza jest
wykonawcą — także zleconym mu wcześniej przez kogoś innego.

### Odczyt materiałów i uwag do poprawy

To samo wejście czytane, nie pisane — po nie sięgasz, gdy masz **sprawdzić czyjąś
robotę** albo **poprawić własną po uwagach**:

```bash
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/tasks/1721/materials"
```

Wraca `sections` (przy zadaniu wieloosobowym jedna na wykonawcę, z `author`), a w każdej
`html`, `revisions` (kolejne tury poprawek, od najstarszej) i `reworkComment` — uwagi
weryfikatora do TEJ osoby. Osobno `reworkReason`: uwagi przy odesłaniu całego zadania
do poprawy. Wszędzie `images`, bo materiały pisze się tym samym edytorem co opis.

Gdy zadanie wróciło **Do poprawy**, uwagi są pierwszą rzeczą do przeczytania — razem
ze zrzutami. Zwykle to na nich widać, o co chodzi, a sam tekst mówi „patrz obrazek".

Odmowy:
- `409 task_not_started` — zadanie jeszcze nierozpoczęte, TMS nie pokazuje wtedy
  sekcji materiałów. Ustaw `in_progress` i powtórz.
- `409 project_done` — projekt zakończony, zadanie tylko do odczytu.
- `403 forbidden` / `403 not_assignee` — właściciel klucza nie jest wykonawcą
  tego zadania. Przy zadaniu wieloosobowym pisze się wyłącznie do własnej części.
- `404` — zadania nie ma albo jest poza jego zasięgiem.

### Oddanie po materiałach

Tu się zatrzymujesz i pytasz. Wyjście podpowiadają `canSelfComplete` i `reviewers`
odczytane przed chwilą — nie zgaduj ich i nie pytaj z góry o weryfikację.

`true` z pustymi `reviewers` — nikt tego nie sprawdza, więc jedyne sensowne
wyjście to zamknięcie:

```
Zadanie 1721 założone, materiały wpisane.
https://tms.firma.pl/tasks/1721

Zamknąć? [zakończone / jeszcze nie]
```

`true`, ale recenzenci są — obie drogi stoją otworem, więc pokaż obie jednym
pytaniem, z imieniem:

```
Zamknąć czy oddać Danielowi do sprawdzenia?
[zakończone / do weryfikacji / jeszcze nie]
```

`false` — zadanie ma nad sobą recenzenta. Co z tym zrobić, zależy od roli
właściciela klucza w projekcie (`myRole` ze słownika).

**Uczestnik** — weryfikacja to jedyna droga, więc nazwij człowieka po imieniu:

```
Oddać Wojtkowi? [do weryfikacji / jeszcze nie]
```

**Kierownik albo właściciel projektu** — pytasz tak jak przy `true` z recenzentami,
bo zamknięcie własnego zadania stoi przed nim otworem mimo tej flagi:

```
Zamknąć czy oddać Danielowi do sprawdzenia?
[zakończone / do weryfikacji / jeszcze nie]
```

Reguła w `rules`, która wybiera za człowieka któreś z tych wyjść, znosi pytanie —
wysyłasz od razu i mówisz, z której reguły to wyszło (patrz „Zmiana statusu").
Dotyczy wyboru drogi, nie samego zapisu materiałów: te wpisujesz tak czy owak.

`jeszcze nie` → zostaje `in_progress`, temat zamknięty.

Po oddaniu potwierdź jednym zdaniem — **z linkiem**, bo to ostatnia rzecz, jaką
człowiek widzi z całej roboty, i często jedyna, do której wraca:

```
Zadanie #1814 czeka na Wojtka jako „Do weryfikacji"
https://tms.firma.pl/tasks/1814
```

## Zadanie z pull requesta

„Załóż zadanie z tego PR-a" — treść bierzesz z GitHuba, nie z pamięci:

```bash
gh pr view 55 --json number,title,body,url,state,headRefName,files
```

Z tego składasz zwykłą propozycję (blok jak w „Propozycji", potwierdzenie jak zawsze):

- **nazwa** — tytuł PR-a, oczyszczony z prefiksów typu `feat:` i numeru gałęzi,
- **opis** — po co ta zmiana, dwa–trzy zdania z opisu PR-a własnymi słowami; nie
  wklejaj całego `body`, zwłaszcza szablonu z checkboxami,
- **materiały** — link do PR-a i co sprawdzić; dopisujesz je dopiero po założeniu,
  tak samo jak przy robocie z rozmowy.

Numer PR-a i link do niego dawaj **zawsze**, w opisie albo w materiałach — bez tego
zadanie nie prowadzi z powrotem do kodu.

Gdy PR jest już scalony, zadanie i tak ma sens (ślad w changelogu), ale powiedz to
w propozycji: człowiek może chcieć od razu `completed` zamiast `in_progress`.

Bez numeru PR-a nie zgaduj — zapytaj o numer albo o link. Nie przeglądaj repozytorium
w poszukiwaniu „tego właściwego" PR-a.

## Czego nie robisz

Nie zatwierdzasz cudzej roboty i nie odsyłasz jej do poprawy — to decyzja
recenzenta, podejmowana po obejrzeniu zadania w TMS, nie w czacie.
Nie zmieniasz projektu ani puli istniejącego zadania — to się robi w TMS.
Nazwę, termin, wykonawcę i recenzentów zmieniasz na prośbę (patrz „Nazwa, priorytet, termin, wykonawca i recenzenci"), nie z własnej
inicjatywy. Opis poprawiasz wyłącznie na wyraźną prośbę (patrz „Poprawa opisu").
Nie zakładasz kilku zadań naraz bez osobnego potwierdzenia każdego.
Nie zamykasz zgłoszeń błędów z własnej inicjatywy — proponujesz, decyduje człowiek.
Nie przeglądasz repozytorium ani kodu na potrzeby stanu zadań — TMS mówi, co
zrobione i co czeka; jeśli trzeba zajrzeć w kod, to osobna robota, nie ta wtyczka.
Nie wysyłasz do TMS treści, których nie było w bloku, który człowiek zatwierdził.
