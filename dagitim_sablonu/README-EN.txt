================================================================
  MY LIBRARY  (Benim Kütüphanem)
  Personal book collection manager
================================================================

A Windows desktop application that keeps track of the books you
own and the ones you want to buy.

Turkish version of this guide: OKUBENI.txt


----------------------------------------------------------------
  RUNNING IT
----------------------------------------------------------------

Double-click BenimKutuphanem.exe

No setup wizard. No database to install. No server window.
The application carries everything it needs.

Sign in with:
      admin / 1234

>> Change your password right after the first sign-in,
   from the "Password" tab inside the application.

The library starts empty. Use the "Add book" button on the
"My Books" tab to start entering your own books.


----------------------------------------------------------------
  SWITCHING THE LANGUAGE
----------------------------------------------------------------

The application opens in Turkish. The "EN" button in the top
right corner switches the whole interface to English; once in
English it reads "TR" and takes you back.

Next to it, the half-moon icon toggles between the light and
dark theme.

Both reset when you close the application, so it always starts
in Turkish with the light theme.

Note: book titles, authors, genres and publishers are YOUR data
and are never translated. If you type them in Turkish, they stay
in Turkish in both languages.


----------------------------------------------------------------
  WHERE YOUR DATA IS
----------------------------------------------------------------

All of your books live in a single file:

  %LOCALAPPDATA%\BenimKutuphanem\kutuphane.db

You can open that folder by pasting this into the Run dialog
(Windows key + R):

  %LOCALAPPDATA%\BenimKutuphanem

TO BACK UP:  close the application, copy kutuphane.db
TO RESTORE:  close the application, copy the file back

Deleting the application does not delete this file; your books
stay. It also survives upgrades, so you never have to enter
them again.

You may see files ending in -wal and -shm next to it. Those are
working files; closing the application before copying is enough.


----------------------------------------------------------------
  WHAT YOU CAN DO
----------------------------------------------------------------

Overview    How many books you own, how many you have read,
            total page count, and the estimated cost of your
            wish list.

My Books    The books you own. Search, filter by genre and by
            read/unread. Add, edit, delete. The switch on each
            row marks a book as read instantly.

Wish List   Books you want to buy, with price and store. Can be
            grouped by genre. Once you buy one, a single button
            moves it into "My Books".

Password    Change your password.

In the author, publisher, genre and store fields you can type a
value that is not in the list; the application adds it for you.

Search ignores Turkish upper/lower case differences: typing
"istanbul" also finds books containing "İSTANBUL".


----------------------------------------------------------------
  TROUBLESHOOTING
----------------------------------------------------------------

The application does not start at all
      The Visual C++ Redistributable (x64) may be missing.
      Install it for free from Microsoft's website and retry.

A "Veritabanı açılamadı" / "Could not open the database" screen
      The folder shown on screen may not be writable, or the
      disk may be full. Read the error text on the screen.

Windows warns about an "unknown publisher"
      Expected: the application is not digitally signed.
      Choose "More info" > "Run anyway".

I forgot my password
      Deleting the database file makes the application start
      fresh (admin / 1234) — but your books go with it.
      Make a copy of the file first.


----------------------------------------------------------------
  WHAT IS IN THIS FOLDER
----------------------------------------------------------------

  BenimKutuphanem.exe   The application
  flutter_windows.dll   User interface library
  sqlite3.dll           Database engine
  data\                 Application resources
  OKUBENI.txt           This guide, in Turkish
  README-EN.txt         This file

Do not move or rename these files; the executable looks for the
others next to it. You can copy the whole folder anywhere — the
application is portable and even runs from a USB stick.


================================================================
  Emir Can Biçen
================================================================
