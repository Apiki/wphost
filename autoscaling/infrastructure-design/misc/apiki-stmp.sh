#!/bin/bash

MAIL_FILE=$(date +%s)-${BASHPID}

while read line; do
    echo "${line}" >> /tmp/${MAIL_FILE}-mail.txt
done < /dev/stdin

## configuration-set
sed  -i '2 a X-SES-CONFIGURATION-SET: SES_ApikiHost' /tmp/${MAIL_FILE}-mail.txt


blacklist=/utils/mails-list.txt
mail_to=$(cat /tmp/${MAIL_FILE}-mail.txt | grep '^To:' | sed 's#To: ##')

grep -c $mail_to $blacklist

[ $? -eq 0 ] && {
	mv  /tmp/${MAIL_FILE}-mail.txt  /tmp/${MAIL_FILE}-mail-blacklisted.txt
	exit 0
}

#Fix Boundary
LINE_BOUNDARY=$(cat /tmp/${MAIL_FILE}-mail.txt | grep -in ^boundary=)

old_IFS=$IFS
IFS=$'\n'
for line in ${LINE_BOUNDARY}; do
	
	line_n=$(cat /tmp/${MAIL_FILE}-mail.txt | grep -in ^boundary= | head -n 1 | cut -d ":" -f1)
	line_content_type=$(( $line_n - 1))
	file_fixed=$( awk -v N=$line_content_type '{if (NR==N) l=$0; else if (NR==N+1) print l $0; else print}' /tmp/${MAIL_FILE}-mail.txt )

	echo "$file_fixed" > /tmp/${MAIL_FILE}-mail.txt
done
IFS=$old_IFS

#SEND------------------------------------------->
cat /tmp/${MAIL_FILE}-mail.txt | /usr/bin/msmtp --logfile /var/log/msmtp.log -a aws2 -t &>> /tmp/${MAIL_FILE}-mail.txt

exit 0
