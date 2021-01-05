#!/bin/bash

#process input and retrieve national weather service page for the given location
City=$1
State=$2
searchQuery="https://forecast.weather.gov/MapClick.php?CityName=$City&state=$State"
inputPage="temp.http"
wget -q "$searchQuery" -O $inputPage

HumidityRaw="$(grep -A1 "Humidity" $inputPage | sed '1d')"
VisibilityRaw="$(grep -A1 "Visibility" $inputPage | sed '1d')"
WindChillRaw="$(grep "Wind Chill" $inputPage)"
WindSpeedRaw="$(grep -A1 "Wind Speed" $inputPage | sed '1d')"
BarometerRaw="$(grep -A1 "Barometer" $inputPage | sed '1d')"
DewPointRaw="$(grep -A1 "Dewpoint" $inputPage | sed '1d')"
TemperatureRaw="$(grep "myforecast-current-sm" $inputPage)"
SkyRaw="$(grep "myforecast-current.>" $inputPage)"

#format raw string and output them to the user
echo "$SkyRaw" | sed -e 's/^[[:space:]]*//g' | sed 's/.*current//g' | tr -d '<>/p\"' | toilet -f pagga
echo "Humidity:    " | tr -d '\n'
echo "$HumidityRaw" | sed -e 's/^[[:space:]]*//g' | tr -d 'td<>/'
echo "Wind Speed:  " | tr -d '\n'
echo "$WindSpeedRaw" | sed -e 's/^[[:space:]]*//g' | tr -d 'td<>/'
echo "Barometer:   " | tr -d '\n'
echo "$BarometerRaw" | sed -e 's/^[[:space:]]*//g' | tr -d 'td<>/'
echo "Temperature: " | tr -d '\n'
echo "$TemperatureRaw" | sed 's/.*sm//g' | tr -d 'p<>deg&/\"' | tr ';' ' '
echo "Visibility:  " | tr -d '\n'
echo "$VisibilityRaw: " | sed -e 's/^[[:space:]]*//g' | tr -d 'td<>/:'
echo "Wind Chill:  " | tr -d '\n'
echo "$WindChillRaw" | sed 's/.*Wind Chill//g' | sed 's/.*F//g' | sed -e 's/^[[:space:]]*//g' | tr -d '()p<>btrdeg&/\"' | tr ';' ' '
echo "Dewpoint:    " | tr -d '\n'
echo "$DewPointRaw" | sed -e 's/^[[:space:]]*//g' | sed 's/.*F//g' | sed -e 's/^[[:space:]]*//g' | tr -d '()p<>btrdeg&/\"' | tr ';' ' '

#show detailed forecast
echo
echo
toilet "Detailed Forecast" -f pagga
grep -o "title=.*\" " $inputPage | sed '1d' | sed 's/title.//g' | sed '10,$d' | tr -d '\"'

#clean up when we are done
rm $inputPage