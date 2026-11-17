# External Gradebook title conversion (SAK-52438)

Companion to [Sakai PR #15381](https://github.com/sakaiproject/sakai/pull/15381).
The Sakai 27 MySQL and Oracle conversion scripts correct common encoded quote,
ampersand, and angle-bracket entities in external Samigo and Assignments titles.
They leave source-tool titles unchanged. Run the conversion while Sakai is stopped,
before starting the upgraded application containing #15381. The SQL uses only
existing tables and data; no upgraded Java code needs to run first.

This conversion is intentionally incomplete. It only changes active, externally
maintained items whose name exactly matches the linked source title. Already
normalized names from older create/export paths, stale names, unmatched sources,
named accents, and most numeric
references (including emoji) are not repaired. It assumes the source title has
Sakai's sanitized/encoded representation; older raw SOAP/import data needs local review.
Ampersands are decoded last so a literal entity is not decoded twice. Changed
names no longer match their source representation, preventing another pass on rerun.
Review proposed names for duplicates within each Gradebook before applying the SQL;
the simple conversion does not resolve name collisions.

## Find remaining encoded emoji and other numeric references

For MySQL 8 / MariaDB:

```sql
SELECT ID, GRADEBOOK_ID, EXTERNAL_APP_NAME, EXTERNAL_ID, NAME
FROM GB_GRADABLE_OBJECT_T
WHERE EXTERNALLY_MAINTAINED = 1 AND REMOVED = 0
  AND EXTERNAL_APP_NAME IN ('sakai.samigo', 'sakai.assignment.grades')
  AND NAME REGEXP '&#([0-9]+|[xX][0-9A-Fa-f]+);';
```

For Oracle (using `CHR(38)` avoids SQL*Plus substitution):

```sql
SELECT ID, GRADEBOOK_ID, EXTERNAL_APP_NAME, EXTERNAL_ID, NAME
FROM GB_GRADABLE_OBJECT_T
WHERE EXTERNALLY_MAINTAINED = 1 AND REMOVED = 0
  AND EXTERNAL_APP_NAME IN ('sakai.samigo', 'sakai.assignment.grades')
  AND REGEXP_LIKE(NAME, CHR(38) || '#([0-9]+|[xX][0-9A-Fa-f]+);');
```

These find numeric references, **not exclusively emoji**. For example, `&#128512;`
and `&#x1F600;` represent 😀, while `&#233;` represents é. Literal entity text can
also match; do not blindly decode every result. To inspect other named entities,
replace the numeric-reference predicate with a search for `&...;` candidates.

## Prompt for a site-specific conversion

> Inspect my Sakai database version, character sets, and the SAK-52438 conversion
> SQL before proposing any changes. I want additional one-time SQL for the titles
> the common conversion leaves behind, without a Java repair service or background job.
> First produce a read-only preview showing item ID, Gradebook ID, old title, expected
> title, and duplicate-name conflicts. Limit changes to linked, externally maintained
> Samigo and Assignments Gradebook items. Derive the expected plain-text title by
> decoding the sanitized source title exactly once, matching Sakai's
> `StringEscapeUtils.unescapeHtml4` behavior. Do not decode an already partially
> converted Gradebook name again or modify source-tool titles. Preserve intentional
> literal entities and report ambiguous/raw legacy source data for manual review.
> Handle the remaining named entities and valid decimal/hexadecimal Unicode references,
> including emoji sequences, without truncation. Verify the destination can store the
> proposed characters; report charset problems without changing the schema. Skip and
> report duplicate target names within a Gradebook. Produce SQL specific to my database,
> guarded by item ID and the previewed old name, plus rollback SQL. Show representative
> before/after examples and make reruns harmless. Do not execute updates without my approval.
