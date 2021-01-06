#!/bin/bash

#process input and retrieve national weather service page for the given location
City="$(echo "$1" | tr ' ' '+')"
State=$2
searchQuery="https://forecast.weather.gov/MapClick.php?CityName=$City&state=$State"
inputPage="temp.http"
wget -q "$searchQuery" -O $inputPage

seperator="$(yes '-' | head -n 120 | tr -d '\n')"
HumidityRaw="$(grep -A1 "Humidity" $inputPage | sed '1d')"
VisibilityRaw="$(grep -A1 "Visibility" $inputPage | sed '1d')"
WindChillRaw="$(grep "Wind Chill" $inputPage)"
WindSpeedRaw="$(grep -A1 "Wind Speed" $inputPage | sed '1d')"
BarometerRaw="$(grep -A1 "Barometer" $inputPage | sed '1d')"
DewPointRaw="$(grep -A1 "Dewpoint" $inputPage | sed '1d')"
TemperatureRaw="$(grep "myforecast-current-sm" $inputPage)"
SkyRaw="$(grep "myforecast-current.>" $inputPage) in $1, $2"
TimeRaw="$(grep -A2 "Last update" $inputPage | sed '1,2d')"


#format raw string and output them to the user
echo "Weather Report As Of" | toilet -f pagga
echo "$TimeRaw" | sed -e 's/^[[:space:]]*//g' | sed 's/\<td\>//g' | tr -d '<>/' | sed -e 's/[[:space:]]*$//g' | toilet -f pagga
echo "$SkyRaw" | sed -e 's/^[[:space:]]*//g' | sed 's/.*current//g' | tr -d '<>/p\"' | toilet -w 100 -f pagga
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
forecastWhole="$(grep -o "title=.*\" " $inputPage | sed '1d' | sed 's/title.//g' | sed '10,$d' | tr -d '\"')"


for i in {1..9}
do
	period="p$i.txt"
	description="d$i.txt"
	sedLine="$(echo "$i p" | tr -d ' ')"
	echo "$forecastWhole" | sed -n "$sedLine" | grep -o ".*:" | toilet -f future > $period
	echo "$forecastWhole" | sed -n "$sedLine" | sed 's/.*://g' | fold -s -w 80 > $description
	paste $period $description | column -s $'\t' -t
	echo "$seperator"
	rm $period $description
done


#clean up when we are done
rm $inputPage
