function mail.export.to.excel {
  if ! [[ "$OSTYPE" =~ .*darwin.* ]]; then echo "This works only on OSX";return 1;fi
  usage="""Usage: 
  ${FUNCNAME[0]}"""
  if [[ "$*" =~ .*--help.* ]];then echo -e "${usage}";return 0;fi
  echo "Exporting emails from Apple Mail to Excel ..."
  osascript - $* <<END
      tell application "Mail" to get mailboxes
      set messageCount to 0
      tell application "Microsoft Excel"
          set LinkRemoval to make new workbook
          set theSheet to active sheet of LinkRemoval
          set formula of range "D1" of theSheet to "Message"
          set formula of range "C1" of theSheet to "Subject"
          set formula of range "B1" of theSheet to "From"
          set formula of range "A1" of theSheet to "Date"
      end tell
      tell application "Mail"
          set theRow to 2
          set theAccount to "Exchange"
          get account theAccount
          repeat with _account in (get accounts)
            if name of _account equals "Exchange"
            end if
          end repeat
          set _year to year of (current date)
          set _archive_box to _account's mailbox "Archive"
          set theMessages to messages of inbox
          repeat with aMessage in theMessages
              try
                my SetDate(date received of aMessage, theRow, theSheet)
                my SetFrom(sender of aMessage, theRow, theSheet)
                my SetSubject(subject of aMessage, theRow, theSheet)
                my SetMessage(content of aMessage, theRow, theSheet)
                set theRow to theRow + 1
                set messageCount to messageCount + 1
                move aMessage to _archive_box
                on error
              end try
          end repeat
          display notification "Finished processing " & messageCount & " email message(s)."
      end tell
      on SetDate(theDate, theRow, theSheet)
          tell application "Microsoft Excel"
              set theRange to "A" & theRow
              set formula of range theRange of theSheet to theDate
          end tell
      end SetDate

      on SetFrom(theSender, theRow, theSheet)
          tell application "Microsoft Excel"
              set theRange to "B" & theRow
              set formula of range theRange of theSheet to theSender
          end tell
      end SetFrom

      on SetSubject(theSubject, theRow, theSheet)
          tell application "Microsoft Excel"
              set theRange to "C" & theRow
              set formula of range theRange of theSheet to theSubject
          end tell
      end SetSubject

      on SetMessage(theMessage, theRow, theSheet)
          tell application "Microsoft Excel"
              set theRange to "D" & theRow
              set formula of range theRange of theSheet to theMessage
          end tell
      end SetMessage
END
}

function mail.export.to.files {
  if ! [[ "$OSTYPE" =~ .*darwin.* ]]; then echo "This works only on OSX"
    return 1
  fi
  usage="""Usage: 
  ${FUNCNAME[0]} <destination>"""
  if [[ "$*" =~ .*--help.* ]];then echo -e "${usage}";return 0;fi
  account=Exchange
  mailbox=inbox
  destination="Macintosh HD:Users:${USER}:Documents:"
  while (( "$#" )); do
    if [[ "$1" =~ .*--account.* ]]; then account=$2;fi    
    if [[ "$1" =~ .*--destination.* ]]; then destination=$2;fi
    if [[ "$1" =~ .*--mailbox.* ]]; then mailbox=$2;fi
    shift
  done
  echo "Exporting emails from Apple Mail to local file system ${export_folder}"
  osascript - <<END
      display notification "Commencing mail export"
      tell application "Mail" to get mailboxes
      set defaultSavePath to "${destination}"
      set messageCount to 0
      set file_extension to "${file_extension}"
      set noarchive to "${noarchive}"
      on extractBetween(SearchText, startText, endText)
        set tid to AppleScript's text item delimiters
        set AppleScript's text item delimiters to startText
        set endItems to text of text item -1 of SearchText
        set AppleScript's text item delimiters to endText
        set beginningToEnd to text of text item 1 of endItems
        set AppleScript's text item delimiters to tid
        return beginningToEnd
      end extractBetween
      on trimStart(str)
        -- Thanks to HAS (http://applemods.sourceforge.net/mods/Data/String.php)
        local str, whiteSpace
        try
          set str to str as string
          set whiteSpace to {character id 10, return, space, tab}
          try
            repeat while str's first character is in whiteSpace
              set str to str's text 2 thru -1
            end repeat
            return str
          on error number -1728
            return ""
          end try
        on error eMsg number eNum
          error "Can't trimStart: " & eMsg number eNum
        end try
      end trimStart            
      tell application "Mail"
          set theAccount to "${account}"
          get account theAccount
          repeat with _account in (get accounts)
            if name of _account equals "${account}"
            end if
          end repeat
          if "${mailbox}" does not equal "inbox" then
            set allMailBoxes to mailboxes of account "${account}"
            set partialName to "${mailbox}"
            repeat with m in allMailBoxes
              if ((offset of partialName in (name of m as string)) is not equal to 0) then
                set ${mailbox} to m
              else 
                display dialog "I coulnd't find specified mailbox '${mailbox}'"
                return
              end if
            end repeat
          end if    
          set _year to year of (current date)
          set _archive_box to _account's mailbox "Archive"
          set theMessages to messages of ${mailbox}
          repeat with aMessage in theMessages
              try
                set msg_date to date received of aMessage
                set msg_date_cleaned to my tpdate(msg_date) as string
                set msg_from to sender of aMessage
                set msg_subj to subject of aMessage
                set msg_subj_cleaned to my cleanSubject(msg_subj)
                set msg_content to content of aMessage
                try 
                  do shell script "uuidgen"
                  set msg_id to msg_date_cleaned & "_" & (get result)
                on error
                  set msg_id to (random number from 1 to 10000) as string
                end try
                set fileName to msg_id & "_" & msg_subj_cleaned & ".txt"
                set filePath to defaultSavePath & fileName                
                set fileContent to content of aMessage
                -- display dialog filePath
                -- Begin File Write
                try
                  tell application "Finder"
                    if not exists filePath as POSIX file then
                      -- write source to the file
                      set the file_ID to open for access filePath with write permission
                      -- set file_ID to open for access file filePath with write permission
                      set eof file_ID to 0
                      write fileContent to file_ID
                      close access file_ID
                    end if
                  end tell        
                on error e number n
                  set marker to "259"
                  display notification e as string & " on line " & marker
                end try   
                -- End Write
                set messageCount to messageCount + 1                
                if noarchive does not equal "true" then
                  move aMessage to _archive_box
                end if
              on error e number n
                -- display dialog e as string
              end try
          end repeat
          display notification "Finished processing " & messageCount & " email message(s)."
      end tell
      on cleanSubject(this_text)
        set c to my replace_chars(this_text, ":", "_")
        set c1 to my replace_chars(c, "'", "_")
        set c2 to my replace_chars(c1, "\"", "_")
        set c3 to my replace_chars(c2, "!", "_")
        set c4 to my replace_chars(c3, "@", "_")
        set c5 to my replace_chars(c4, "#", "_")
        set c6 to my replace_chars(c5, "$", "_")
        set c7 to my replace_chars(c6, "%", "_")
        set c8 to my replace_chars(c7, "^", "_")
        set c9 to my replace_chars(c8, "&", "_")
        set c10 to my replace_chars(c9, "*", "_")
        set c11 to my replace_chars(c10, "(", "_")
        set c12 to my replace_chars(c11, ")", "_")
        set c13 to my replace_chars(c12, "-", "_")
        set c14 to my replace_chars(c13, "/", "_")
        set c15 to my replace_chars(c14, ">", "_")
        set c16 to my replace_chars(c15, " ", "_")
        return c16
      end cleanSubject
      on tpdate(mydate) 
        set y to text -4 thru -1 of ("0000" & (year of mydate))
        set m to text -2 thru -1 of ("00" & ((month of mydate) as integer))
        set d to text -2 thru -1 of ("00" & (day of mydate))
        set theTime to time of mydate
        set theHour to theTime div 3600
        set finalHour to text -2 thru -1 of ("00" & theHour)
        set theMinute to theTime mod 3600 div 60
        set finalMinute to text -2 thru -1 of ("00" & theMinute)
        set theSecond to theTime mod 3600 mod 60
        set finalSecond to text -2 thru -1 of ("00" & theSecond)
        set finalTime to finalHour & finalMinute & finalSecond        
        -- return y & m & d & t & finalTime
        return y & m & d & finalTime
      end tpdate      
      on replace_chars(this_text, search_string, replacement_string)
        set AppleScript's text item delimiters to the search_string
        set the item_list to every text item of this_text
        set AppleScript's text item delimiters to the replacement_string
        set this_text to the item_list as string
        set AppleScript's text item delimiters to ""
        return this_text
      end replace_chars
      on pad(n)
        return text -2 thru -1 of ("00" & n)
      end pad   
      (*  
      ======================================
      // HTML CLEANUP SUBROUTINES 
      =======================================
      *)
      --HEADER STRIP (THANKS DOMINIK!)
      on stripHeader(msg_source_paragraphs, msg_source_headers)
        
        -- FIND THE LAST NON-EMPTY HEADER LINE
        set lastheaderline to ""
        set n to count (msg_source_headers)
        repeat while (lastheaderline = "")
          set lastheaderline to item n of msg_source_headers
          set n to n - 1
        end repeat
        
        -- COMPARE HEADER TO SOURCE
        set sourcelength to (count msg_source_paragraphs)
        repeat with n from 1 to sourcelength
          if (item n of msg_source_paragraphs is equal to "") then exit repeat
        end repeat
        
        -- STRIP OUT THE HEADERS
        set msg_source_trimmedItems to (items (n + 1) thru sourcelength of msg_source_paragraphs)
        set oldDelims to AppleScript's text item delimiters
        set AppleScript's text item delimiters to return
        set msg_source_trimmed to (msg_source_trimmedItems as text)
        set AppleScript's text item delimiters to oldDelims
        return msg_source_trimmed
      end stripHeader    
      --BASE64 CHECK
      on base64_Check(msg_source)
        set base64Detect to false
        set base64MsgStr to "Content-Transfer-Encoding: base64"
        set base64ContentType to "Content-Type: text"
        set base64MsgOffset to offset of base64MsgStr in msg_source
        set base64ContentOffset to offset of base64ContentType in msg_source
        set base64Offset to base64MsgOffset - base64ContentOffset as real
        set theOffset to base64Offset as number
        if theOffset is not greater than or equal to 50 then
          if theOffset is greater than -50 then set base64Detect to true
        end if
        return base64Detect
      end base64_Check    
      --BASE64 DECODE
      on base64_Decode(msg_source)
        --USE TID TO QUICKLY ISOLATE BASE64 DATA
        set oldDelim to AppleScript's text item delimiters
        set AppleScript's text item delimiters to "Content-Type: text/html"
        set base64_Raw to second text item of msg_source
        set AppleScript's text item delimiters to linefeed & linefeed
        set base64_Raw to second text item of base64_Raw
        set AppleScript's text item delimiters to "-----"
        set multiHTML to first text item of base64_Raw
        set AppleScript's text item delimiters to oldDelim
        --DECODE BASE64
        set msg_content_final to do shell script "echo " & (quoted form of multiHTML) & "| base64 -D"
        return msg_content_final
      end base64_Decode
      --HTML FIX
      on htmlFix(multiHTML, msg_source_boundary, msg_body)
        set oldDelims to AppleScript's text item delimiters
        set msg_source_paragraphs to paragraphs of multiHTML
        if item 1 of msg_source_paragraphs contains "Received:" then
          set msg_source_headers to (item 1 of msg_source_paragraphs)
          set multiHTML to my stripHeader(msg_source_paragraphs, msg_source_headers)
        end if
        --TRIM ENDING
        if multiHTML contains "</html>" then
          set multiHTML to my extractBetween(multiHTML, "Content-Type: text/html", "</html>")
        else
          set multiHTML to my extractBetween(multiHTML, "Content-Type: text/html", "--" & msg_source_boundary)
        end if
        set msg_source_paragraphs to paragraphs of multiHTML
        --TEST FOR / STRIP OUT LEADING SEMI-COLON
        if item 1 of msg_source_paragraphs contains ";" then
          set msg_source_headers to (item 1 of msg_source_paragraphs)
          set multiHTML to my stripHeader(msg_source_paragraphs, msg_source_headers)
          set msg_source_paragraphs to paragraphs of multiHTML
        end if
        --TEST FOR EMPTY LINE / CLEAN SUBSEQUENT ENCODING INFO, IF NECESSARY
        if item 1 of msg_source_paragraphs is "" then
          --TEST FOR / STRIP OUT CONTENT-TRANSFER-ENCODING
          if item 2 of msg_source_paragraphs contains "Content-Transfer-Encoding" then
            set msg_source_headers to (item 2 of msg_source_paragraphs)
            set multiHTML to my stripHeader(msg_source_paragraphs, msg_source_headers)
            set msg_source_paragraphs to paragraphs of multiHTML
          end if
          --TEST FOR / STRIP OUT CHARSET
          if item 2 of msg_source_paragraphs contains "charset" then
            set msg_source_headers to (item 2 of msg_source_paragraphs)
            set multiHTML to my stripHeader(msg_source_paragraphs, msg_source_headers)
            set msg_source_paragraphs to paragraphs of multiHTML
          end if
        end if
        --TEST FOR / STRIP OUT CONTENT-TRANSFER-ENCODING
        if item 1 of msg_source_paragraphs contains "Content-Transfer-Encoding" then
          set msg_source_headers to (item 1 of msg_source_paragraphs)
          set multiHTML to my stripHeader(msg_source_paragraphs, msg_source_headers)
          set msg_source_paragraphs to paragraphs of multiHTML
        end if
        --TEST FOR / STRIP OUT CHARSET
        if item 1 of msg_source_paragraphs contains "charset" then
          set msg_source_headers to (item 1 of msg_source_paragraphs)
          set multiHTML to my stripHeader(msg_source_paragraphs, msg_source_headers)
          set msg_source_paragraphs to paragraphs of multiHTML
        end if
        --CLEAN CONTENT
        set AppleScript's text item delimiters to msg_source_boundary
        set theSourceItems to text items of multiHTML
        set AppleScript's text item delimiters to ""
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to "%"
        set theSourceItems to text items of theEncoded
        set AppleScript's text item delimiters to "&#" & "37;" as string
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to "="
        set theSourceItems to text items of theEncoded
        set AppleScript's text item delimiters to "%"
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to "%\""
        set theSourceItems to text items of theEncoded
        set AppleScript's text item delimiters to "=\""
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to "%" & (ASCII character 13)
        set theSourceItems to text items of theEncoded
        set AppleScript's text item delimiters to ""
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to "%%"
        set theSourceItems to text items of theEncoded
        set AppleScript's text item delimiters to "%"
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to "%" & (ASCII character 10)
        set theSourceItems to text items of theEncoded
        set AppleScript's text item delimiters to ""
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to "%0A"
        set theSourceItems to text items of theEncoded
        set AppleScript's text item delimiters to ""
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to "%09"
        set theSourceItems to text items of theEncoded
        set AppleScript's text item delimiters to ""
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to "%C2%A0"
        set theSourceItems to text items of theEncoded
        set AppleScript's text item delimiters to "&nbsp;"
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to "%20"
        set theSourceItems to text items of theEncoded
        set AppleScript's text item delimiters to " "
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to (ASCII character 10)
        set theSourceItems to text items of theEncoded
        set AppleScript's text item delimiters to ""
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to "="
        set theSourceItems to text items of theEncoded
        set AppleScript's text item delimiters to "&#" & "61;" as string
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to "$"
        set theSourceItems to text items of theEncoded
        set AppleScript's text item delimiters to "&#" & "36;" as string
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to "'"
        set theSourceItems to text items of theEncoded
        set AppleScript's text item delimiters to "&apos;"
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to "\""
        set theSourceItems to text items of theEncoded
        set AppleScript's text item delimiters to "\\\" & "\""
        set theEncoded to theSourceItems as text
        set AppleScript's text item delimiters to oldDelims
        set trimHTML to my extractBetween(theEncoded, "</head>", "</html>")
        set theHTML to msg_body
        try
          set decode_Success to false
          --UTF-8 CONV
          set NewEncodedText to do shell script "echo " & quoted form of trimHTML & " | iconv -t UTF-8 "
          set the_UTF8Text to quoted form of NewEncodedText
          --URL DECODE CONVERSION
          set theDecodeScript to "php -r \"echo utf8_encode(urldecode(utf8_decode(" & the_UTF8Text & ")));\"" as text
          set theDecoded to do shell script theDecodeScript
          --FIX FOR APOSTROPHE / PERCENT / EQUALS ISSUES
          set AppleScript's text item delimiters to "&apos;"
          set theSourceItems to text items of theDecoded
          set AppleScript's text item delimiters to "'"
          set theDecoded to theSourceItems as text
          set AppleScript's text item delimiters to "&#" & "37;" as string
          set theSourceItems to text items of theDecoded
          set AppleScript's text item delimiters to "%"
          set theDecoded to theSourceItems as text
          set AppleScript's text item delimiters to "&#" & "61;" as string
          set theSourceItems to text items of theDecoded
          set AppleScript's text item delimiters to "="
          set theDecoded to theSourceItems as text
          --RETURN THE VALUE
          set msg_content_final to theDecoded
          set decode_Success to true
          return msg_content_final
        end try
      end htmlFix      
END
}