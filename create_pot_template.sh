#!/bin/sh
# Creates a pot template ready for transifex upload.

APP_NAME="vera"

# Necessary step
bake build

cd po/$APP_NAME

cat > ${APP_NAME}-upload.pot <<EOF
msgid ""
msgstr ""
"Project-Id-Version: PACKAGE VERSION\n"
"Report-Msgid-Bugs-To: \n"
"POT-Creation-Date: 2015-03-20 20:35+0100\n"
"PO-Revision-Date: YEAR-MO-DA HO:MI+ZONE\n"
"Last-Translator: FULL NAME <EMAIL@ADDRESS>\n"
"Language-Team: LANGUAGE <LL@li.org>\n"
"Language: \n"
"MIME-Version: 1.0\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Content-Transfer-Encoding: 8bit\n"
EOF

tail -n+3 $APP_NAME.pot >> ${APP_NAME}-upload.pot
