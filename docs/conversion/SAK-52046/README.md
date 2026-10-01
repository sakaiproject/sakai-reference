# SAK-52046 tag collection conversion

The MySQL and Oracle migrations are the SAK-52046 sections of `../sakai_26_mysql_conversion.sql` and `../sakai_26_oracle_conversion.sql`, after the SAK-52889 Tags/Taggable merger. `hsqldb.sql` supplies the equivalent standalone HSQLDB conversion.

Run the appropriate conversion once, with Sakai stopped, after taking a database backup. Apply the earlier Tags/Taggable merger conversion first. This conversion must run before starting the version containing the `siteid` mapping; automatic schema updates cannot classify existing collections.

| Existing collection | Scope after conversion |
| --- | --- |
| Collection ID matches a site ID | That site |
| Collection ID matches a user ID | That user’s workspace (`~userId`) |
| Other collections, including imported vocabularies | Global |

Personal Messages tags are copied into each site where their message associations occur. The conversion uses Messages recipient context IDs, updates the associations, preserves nullable metadata, and handles repeated recipients. Personal originals remain available to Samigo pools and questions. Unused personal tags remain private because there is no reliable site to assign them to.

Samigo pools are user-owned and can be shared across sites. Their tags remain user-owned; pool selectors also offer global tags. Questions authored in a site can select site and global collections. Existing question tag IDs are preserved, including questions shared through pools.

The conversion also adds the Tags tool to the Admin Workspace if it is missing. Fresh installations get the tool through the normal workspace seed data. Collections created there are global; collections created in a course or project are local. Instructors can view and select global tags but cannot edit them.

`tagservice.enable.integrations` supplies the default for Assignments, Messages, and Samigo authoring. Explicit `samigo.author.usetags` settings continue to override the Samigo default. Samigo grading display settings are unchanged.

These conversions accompany [sakaiproject/sakai#15086](https://github.com/sakaiproject/sakai/pull/15086). Apply them before starting that application version. If the SAK-52889 conversion was already applied, run only the new SAK-52046 section; do not rerun the complete release conversion.
