# Collection of scripts for [8x8's VOA API](https://8x8gateway-voanalytics.apigee.io)

The current API endpoints:
* Call Detail Records
  * Trace specific calls within a selected time frame
* Extension Summary
  * Obtain a detailed summary of call activity for any extension
* Company Summary
  * Obtain summary information about your enterprise
* Meetings
  * Obtain summary information about virtual meetings for a given time period
  
**You must obtain an API Key from your 8x8 account manager**

**Release History**

  * 2020-04-11 - Release of 8x8_VOA_CDR.php

    * 8x8_VOA_CDR.php will produce a CSV of all available fields returned from the Call Detail Records endpoint
    * It is a PHP CLI script which has been tested on MacOS Mojave 10.15.4 using PHP 7.3.11
    * Has been used to pull all historical data on a PBX which returned 31MM+ records
    * Populate: 
      ```
      $config["voa"]["8x8-apikey"] = '';
      $config["voa"]["username"] = '';
      $config["voa"]["password"] = '';
      ```
