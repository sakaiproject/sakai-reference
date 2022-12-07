-- SAK-44753
alter table rbc_tool_item_rbc_assoc add constraint UKq4btc0dfymi80bb5mp3vp3r7u unique (rubric_id, toolId, itemId);
-- END SAK-44753

