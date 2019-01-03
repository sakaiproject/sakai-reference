# Sakai Localization (L10N)

From its inception, the Sakai project has been envisioned and designed for global use. Complete or majority-complete translations of Sakai are available in more than 20 languages listed below. 

Translation, internationalization and localization of the Sakai project are coordinated by the Sakai Internationalization/localization community. This community maintains a publicly-accessible report that tracks what percentage of Sakai has been translated into various global languages and dialects. If the software is not yet available in your language, you can translate it with support from the broader Sakai Community to assist you. 

### Spanish (Spain)

| Status | Supported [90% - 100%](https://www.transifex.com/apereo/sakai-trunk/)|
| ------ | ------ |
| Contact | [Spanish Sakai](mailto:sakai-spanish@apereo.org) |
| Local ID | es_ES |

### Catalan

| Status | Supported [90% - 100%](https://www.transifex.com/apereo/sakai-trunk/)|
| ------ | ------ |
| Translated by | [Universitat de LLeida](http://udl.cat) |
| Contact | [Àlex Ballesté](mailto:alexandre.balleste@udl.cat) |
| Local ID | ca_ES |

### Basque

| Status | Supported [80% - 90%](https://www.transifex.com/apereo/sakai-trunk/)|
| ------ | ------ |
| Translated by | [Universidad Pública de Navarra](http://www.unavarra.es/) |
| Contact | [Pablo San Roman](mailto:pablo.sanroman@unavarra.es) |
| Local ID | eu |

### Japanese

| Status | Supported [90% - 100%](https://www.transifex.com/apereo/sakai-trunk/)|
| ------ | ------ |
| Translated by | Ja Sakai Community |
| Contact | [Sakai development](mailto:sakai-dev@apereo.org) |
| Local ID | ja_JP |

### Swedish

| Status | Supported [70% - 90%](https://www.transifex.com/apereo/sakai-trunk/)|
| ------ | ------ |
| Contact | [Sakai development](mailto:sakai-dev@apereo.org) |
| Local ID | sv_SE |

### French (France)

| Status | Unverified|
| ------ | ------ |
| Translated by | French Sakai Community |
| Contact | [Sakai development](mailto:sakai-dev@apereo.org) |
| Local ID | fr_FR |

### Persian (Iran)

| Status | Unverified|
| ------ | ------ |
| Translated by | Seyed Muhammad Hussain Jamali|
| Contact | [Sakai development](mailto:sakai-dev@apereo.org) |
| Local ID | fa_IR |

### Chinese/Simplified (China)

| Status | Unverified|
| ------ | ------ |
| Translated by | Fudan University |
| Contact | [高珺](mailto:gaojun@fudan.edu.cn) |
| Local ID | zh_CN |

### Turkish

| Status | Supported [90% - 100%](https://www.transifex.com/apereo/sakai-trunk/)|
| ------ | ------ |
|Contact|[Yasin OZARSLAN](mailto:ozarslan@gmail.com)|
|Contact|[Emrah Emirtekin](mailto:eemirtekin@gmail.com)|
| Local ID | tr_TR |

### Brazilian Portuguese

| Status | Unverified|
| ------ | ------ |
| Translated by | Eduardo Hideki Tanaka |
| Contact | [Sakai development](mailto:sakai-dev@apereo.org) |
| Local ID | pt_BR |

### Mongolian
| Status | Unverified|
| ------ | ------ |
| Contact | [Sakai development](mailto:sakai-dev@apereo.org) |
| Local ID | mn_MN |

### Hindi
| Status | Unverified|
| ------ | ------ |
| Contact | [Sakai development](mailto:sakai-dev@apereo.org) |
| Local ID | hi_IN |

### Other languages

Other languages have been declared legacy in Sakai 19 and have been moved to [Sakai Contrib as language packs](https://github.com/sakaicontrib/legacy-language-packs).

Feel free to contact the [Sakai DEV list](mailto:sakai-dev@apereo) if you wish to include a new language in Sakai.

## Set the default language of the platform

The default language locale must be defined at boot time (though this can be over-ridden by user preferences), by setting the tomcat JAVA_OPTS property as follows:

Linux:
```
## Define default language locale: Japanese / Japan
JAVA_OPTS="$JAVA_OPTS -Duser.language=ja -Duser.region=JP"
```
Windows:
```
rem Define default language locale: Japanese / Japan
set JAVA_OPTS=%JAVA_OPTS% -Duser.language=ja -Duser.region=JP
```
