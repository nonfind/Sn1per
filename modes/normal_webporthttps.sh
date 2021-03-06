if [ "$MODE" = "web" ]; then
  if [ "$SLACK_NOTIFICATIONS" == "1" ]; then
    /usr/bin/python "$INSTALL_DIR/bin/slack.py" "[xerosecurity.com] •?((¯°·._.• Started Sn1per HTTPS web scan: $TARGET [$MODE] (`date +"%Y-%m-%d %H:%M"`) •._.·°¯))؟•"
  fi
  if [ "$PASSIVE_SPIDER" == "1" ]; then
    echo -e "${OKGREEN}====================================================================================${RESET}"
    echo -e "$OKRED RUNNING PASSIVE WEB SPIDER $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}"
    curl -sX GET "http://index.commoncrawl.org/CC-MAIN-2018-22-index?url=*.$TARGET&output=json" | jq -r .url | tee $LOOT_DIR/web/passivespider-$TARGET.txt 2> /dev/null
  fi
  if [ "$WAYBACKMACHINE" == "1" ]; then
    echo -e "${OKGREEN}====================================================================================${RESET}"
    echo -e "$OKRED FETCHING WAYBACK MACHINE URLS $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}"
    curl -sX GET "http://web.archive.org/cdx/search/cdx?url=*.$TARGET/*&output=text&fl=original&collapse=urlkey" | tee $LOOT_DIR/web/waybackurls-$TARGET.txt 2> /dev/null
  fi
  if [ "$BLACKWIDOW" == "1" ]; then
    echo -e "${OKGREEN}====================================================================================${RESET}"
    echo -e "$OKRED RUNNING ACTIVE WEB SPIDER & APPLICATION SCAN $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}"
    blackwidow -u https://$TARGET:443 -l 3 -s y -v n
    cat /usr/share/blackwidow/$TARGET*/$TARGET*.txt 2> /dev/null > $LOOT_DIR/web/spider-$TARGET.txt 2>/dev/null
    cat $LOOT_DIR/web/waybackurls-$TARGET.txt 2> /dev/null >> $LOOT_DIR/web/spider-$TARGET.txt 2>/dev/null
    cat $LOOT_DIR/web/weblinks-https-$TARGET.txt 2> /dev/null >> $LOOT_DIR/web/spider-$TARGET.txt 2>/dev/null
    cat $LOOT_DIR/web/passivespider-$TARGET.txt 2> /dev/null >> $LOOT_DIR/web/spider-$TARGET.txt 2>/dev/null
    sed -ir "s/</\&lh\;/g" $LOOT_DIR/web/spider-$TARGET.txt 2>/dev/null
  fi
  if [ "$WEB_BRUTE_COMMONSCAN" == "1" ]; then
      echo -e "${OKGREEN}====================================================================================${RESET}"
      echo -e "$OKRED RUNNING COMMON FILE/DIRECTORY BRUTE FORCE $RESET"
      echo -e "${OKGREEN}====================================================================================${RESET}"
      if [ "$DIRSEARCH" == "1" ]; then
        python3 $PLUGINS_DIR/dirsearch/dirsearch.py -u https://$TARGET -w $WEB_BRUTE_STEALTH -x 400,403,404,405,406,429,502,503,504 -F -e $WEB_BRUTE_EXTENSIONS -f -r -t $THREADS --random-agents
        python3 $PLUGINS_DIR/dirsearch/dirsearch.py -u https://$TARGET -w $WEB_BRUTE_COMMON -x 400,403,404,405,406,429,502,503,504 -F -e * -t $THREADS --random-agents
      fi
      if [ "$GOBUSTER" == "1" ]; then
          gobuster -u https://$TARGET -w $WEB_BRUTE_COMMON -e | tee $LOOT_DIR/web/gobuster-$TARGET-https-common.txt
      fi
  fi
  if [ "$WEB_BRUTE_FULLSCAN" == "1" ]; then
      echo -e "${OKGREEN}====================================================================================${RESET}"
      echo -e "$OKRED RUNNING FULL FILE/DIRECTORY BRUTE FORCE $RESET"
      echo -e "${OKGREEN}====================================================================================${RESET}"
      if [ "$DIRSEARCH" == "1" ]; then
          python3 $PLUGINS_DIR/dirsearch/dirsearch.py -u https://$TARGET -w $WEB_BRUTE_FULL -x 400,403,404,405,406,429,502,503,504 -F -e * -t $THREADS --random-agents
      fi
      if [ "$GOBUSTER" == "1" ]; then
          gobuster -u https://$TARGET -w $WEB_BRUTE_FULL -e | tee $LOOT_DIR/web/gobuster-$TARGET-https-full.txt
      fi
  fi
  if [ "$WEB_BRUTE_EXPLOITSCAN" == "1" ]; then
      echo -e "${OKGREEN}====================================================================================${RESET}"
      echo -e "$OKRED RUNNING FILE/DIRECTORY BRUTE FORCE FOR VULNERABILITIES $RESET"
      echo -e "${OKGREEN}====================================================================================${RESET}"
      if [ "$DIRSEARCH" == "1" ]; then
          python3 $PLUGINS_DIR/dirsearch/dirsearch.py -u https://$TARGET -w $WEB_BRUTE_EXPLOITS -x 400,403,404,405,406,429,502,503,504 -F -e * -t $THREADS --random-agents
      fi
      if [ "$GOBUSTER" == "1" ]; then
          gobuster -u https://$TARGET -w $WEB_BRUTE_EXPLOITS -e | tee $LOOT_DIR/web/gobuster-$TARGET-https-exploits.txt
      fi
  fi
  if [ "$DIRSEARCH" == "1" ]; then
      cat $PLUGINS_DIR/dirsearch/reports/$TARGET/* 2> /dev/null
      cat $PLUGINS_DIR/dirsearch/reports/$TARGET/* > $LOOT_DIR/web/dirsearch-$TARGET.txt 2> /dev/null
  fi
  if [ "$GOBUSTER" == "1" ]; then
      sort -u $LOOT_DIR/web/webbrute-$TARGET-*.txt 2> /dev/null > $LOOT_DIR/web/webbrute-$TARGET.txt 2> /dev/null
  fi
  wget https://$TARGET/robots.txt -O $LOOT_DIR/web/robots-$TARGET-https.txt 2> /dev/null
  if [ "$NMAP_SCRIPTS" == "1" ]; then
    echo -e "${OKGREEN}====================================================================================${RESET}"
    echo -e "$OKRED RUNNING NMAP HTTP SCRIPTS $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}"
    nmap -A -sV -T5 -Pn -p 443 --script=/usr/share/nmap/scripts/iis-buffer-overflow.nse --script=http-vuln* $TARGET | tee $LOOT_DIR/output/nmap-$TARGET-port443
    sed -r "s/</\&lh\;/g" $LOOT_DIR/output/nmap-$TARGET-port443 2> /dev/null > $LOOT_DIR/output/nmap-$TARGET-port443.txt 2> /dev/null
    rm -f $LOOT_DIR/output/nmap-$TARGET-port443 2> /dev/null
  fi
  if [ "$CLUSTERD" == "1" ]; then
      echo -e "${OKGREEN}====================================================================================${RESET}"
      echo -e "$OKRED ENUMERATING WEB SOFTWARE $RESET"
      echo -e "${OKGREEN}====================================================================================${RESET}"
      clusterd --ssl -i $TARGET 2> /dev/null | tee $LOOT_DIR/web/clusterd-$TARGET-https.txt
  fi
  if [ "$CMSMAP" == "1" ]; then
      echo -e "${OKGREEN}====================================================================================${RESET}"
      echo -e "$OKRED RUNNING CMSMAP $RESET"
      echo -e "${OKGREEN}====================================================================================${RESET}"
      cmsmap https://$TARGET | tee $LOOT_DIR/web/cmsmap-$TARGET-httpsa.txt
      echo ""
      cmsmap https://$TARGET/wordpress/ | tee $LOOT_DIR/web/cmsmap-$TARGET-httpsb.txt
      echo ""
  fi
  if [ "$WPSCAN" == "1" ]; then
      echo -e "${OKGREEN}====================================================================================${RESET}"
      echo -e "$OKRED RUNNING WORDPRESS VULNERABILITY SCAN $RESET"
      echo -e "${OKGREEN}====================================================================================${RESET}"
      wpscan --url https://$TARGET --no-update --disable-tls-checks 2> /dev/null | tee $LOOT_DIR/web/cmsmap-$TARGET-httpsa.txt
      echo ""
      wpscan --url https://$TARGET/wordpress/ --no-update --disable-tls-checks 2> /dev/null | tee $LOOT_DIR/web/cmsmap-$TARGET-httpsb.txt
  fi
  if [ "$NIKTO" == "1" ]; then
    echo -e "${OKGREEN}====================================================================================${RESET}"
    echo -e "$OKRED RUNNING WEB VULNERABILITY SCAN $RESET"
    echo -e "${OKGREEN}====================================================================================${RESET}"
    nikto -h https://$TARGET -output $LOOT_DIR/web/nikto-$TARGET-http-port443.txt
    sed -ir "s/</\&lh\;/g" $LOOT_DIR/web/nikto-$TARGET-http-port443.txt
  fi
  if [ "$SHOCKER" = "1" ]; then
      echo -e "${OKGREEN}====================================================================================${RESET}"
      echo -e "$OKRED RUNNING SHELLSHOCK EXPLOIT SCAN $RESET"
      echo -e "${OKGREEN}====================================================================================${RESET}"
      python $PLUGINS_DIR/shocker/shocker.py -H $TARGET --cgilist $PLUGINS_DIR/shocker/shocker-cgi_list --ssl --port 443 | tee $LOOT_DIR/web/shocker-$TARGET-port443.txt
  fi
  if [ "$JEXBOSS" = "1" ]; then
      echo -e "${OKGREEN}====================================================================================${RESET}"
      echo -e "$OKRED RUNNING JEXBOSS $RESET"
      echo -e "${OKGREEN}====================================================================================${RESET}"
      cd /tmp/
      python /usr/share/sniper/plugins/jexboss/jexboss.py -u https://$TARGET | tee $LOOT_DIR/web/jexboss-$TARGET-port443.raw
      sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g" $LOOT_DIR/web/jexboss-$TARGET-port443.raw > $LOOT_DIR/web/jexboss-$TARGET-port443.txt 2> /dev/null
      rm -f $LOOT_DIR/web/jexboss-$TARGET-port443.raw 2> /dev/null
      cd $INSTALL_DIR
  fi
  if [ "$SLACK_NOTIFICATIONS" == "1" ]; then
    /usr/bin/python "$INSTALL_DIR/bin/slack.py" "[xerosecurity.com] •?((¯°·._.• Finished Sn1per HTTPS web scan: $TARGET [$MODE] (`date +"%Y-%m-%d %H:%M"`) •._.·°¯))؟•"
  fi
  cd $INSTALL_DIR
  if [ "$METASPLOIT_EXPLOIT" == "1" ]; then
      PORT="443"
      SSL="true"
      source modes/web_autopwn.sh
  fi
fi