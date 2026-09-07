# Praca w tym repozytorium

## Wersja — cztery miejsca, jednym ruchem

Numer wersji siedzi w czterech miejscach. **Podbijasz wszystkie naraz, w jednym
commicie:**

1. `.claude-plugin/plugin.json`
2. `.claude-plugin/marketplace.json`
3. `skills/ustawienia/SKILL.md` — sekcja „Wersja" i przykładowy blok pod nią
4. wydanie na GitHubie: `gh release create vX.Y.Z --target main`

Punkt 3 to numer, który wtyczka melduje człowiekowi. Rozjazd z resztą znaczy, że
`/tms:ustawienia` kłamie o tym, co jest wczytane — a to jedyne miejsce, z którego
da się to sprawdzić.

Zanim wypchniesz podbicie, sprawdź, że nic nie zostało:

```bash
grep -rn "0\.31\.2" --include=*.md --include=*.json .
```

## Numeru wydanego nie nadpisujesz

**Cache wtyczek jest kluczowany numerem wersji.** Katalog `~/.claude/plugins/cache/
jf-tms/tms/<wersja>/` raz pobrany nie odświeża się już nigdy — odświeżanie źródła
widzi ten numer i uznaje, że ma swoje.

Wniosek: **cokolwiek dopchniesz pod numerem, który komuś już się pobrał, do tej
osoby nie dotrze.** Poprawka do wydanej wersji to zawsze nowy numer, nawet gdy
zmieniasz jedną linijkę. Zdarzyło się naprawdę: 0.31.2 poszło z poprawką numeru
wysłaną po fakcie i u nikogo się nie pojawiło — trzeba było wydać 0.31.3.

## Zadanie w TMS po scaleniu

**Samo wydanie zadania nie potrzebuje.** Nie zakładaj osobnego zadania tylko po to,
żeby odnotować, że coś wyszło — od tego jest wydanie na GitHubie.

Gdy robota miała już swoje zadanie (bo ktoś ją zgłosił albo zaplanował), prowadzisz
je do końca: materiały do weryfikacji z linkiem do PR-a i tym, co sprawdzić, a potem
status. Nie dublujesz go drugim zadaniem „o wydaniu".

## Czego nie robisz

Nie zmieniasz zachowania wtyczki przy okazji podbijania wersji — wydanie porządkowe
zostaje porządkowe.
