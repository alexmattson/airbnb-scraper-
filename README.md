Airbnb Scraper
=============

This is a simple airbnb scraper in ruby. 

It is a script that can run daily where it would pull all the information from lisings in a given area and store it into a CSV file. 

Expantion and Known Issues
-----------

Feel free to fix any of the issues or expand on any of the features listed below:

Issues:

0. Check if booked -  Currently, the way the script checks if a booking has occurred, is to wait for the javascript on the page to load the calendar. This is done with a sleep delay every time it visits a given listing (see `go_to(url)` method). This method is sluggish and causes the whole system to move slow. 
0. Date - `set_date_URL()` method currently does not properly take into account end of months and end of years.
0. CSV needs to check if listing currently exists (should be put off until converted to rails application and setup as a database rather then a CSV printout)

Features:

0. Convert this over to full Ruby on Rails application
0. Database structuring rather then CSV printout

Installation
-----------

Requires the following gems

watir-webdriver

```
gem install watir
```

phantomjs

```
gem install phantomjs
```

nokogiri

```
gem install nokogiri
```

rest-client

```
gem install rest-client
```

