# Database migrations

- MySQL 8 and Oracle are both required targets. Include equivalent changes in both conversion scripts.
- Keep SQL simple and direct. Prefer ordinary DDL and DML over stored procedures, dynamic SQL, or catalog inspection unless those are necessary.
- Preserve existing data and keep defaults and nullability consistent across both databases.
- Validate on the actual targets when available. Clearly state when a target was not tested; MariaDB execution does not establish MySQL 8 compatibility.
