# Plex setup for homeserver

```sh
# download the script
curl -L -o plex-claim-server.sh https://github.com/uglymagoo/plex-claim-server/raw/master/plex-claim-server.sh
# make the script executable
chmod +x plex-claim-server.sh
# go to https://www.plex.tv/claim/ in your browser and get the claim token and replace PLEX_CLAIM with this token in the next command, please use use the double quotes around your claim token
./plex-claim-server.sh "PLEX_CLAIM"
# fix permissions
chown plex:plex "/config/Library/Application Support/Plex Media Server/Preferences.xml"
# leave the container
exit
```
