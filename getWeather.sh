#!/bin/bash

#process input and retrieve national weather service page for the given location
City="$(echo "$1" | tr ' ' '+')"
State=$2
NC='\\033\[0m'
RED='\\033\[0;31m'
BLUE='\\033\[0;34m'
GREEN='\\033\[0;32m'
YELLOW='\\033\[0;33m'
CYAN='\\033\[0;36m'

#set message width
if [ $# -eq 3 ]
then
	width=$3
else
	width=$(stty -a < $(tty) | grep -Po '(?<=columns )\d+')
fi

searchQuery="https://forecast.weather.gov/MapClick.php?CityName=$City&state=$State"
inputPage="temp.html"
wget -q "$searchQuery" -O $inputPage

#extract weather variables from the webpage source
seperatorA="$(yes '-' | head -n $width | tr -d '\n')"
seperatorB="$(yes '=' | head -n $width | tr -d '\n')"
HumidityRaw="$(grep -A1 "Humidity" $inputPage | sed '1d')"
VisibilityRaw="$(grep -A1 "Visibility" $inputPage | sed '1d')"
WindChillRaw="$(grep "<b>Wind Chill" $inputPage)"
WindSpeedRaw="$(grep -A1 "Wind Speed" $inputPage | sed '1d')"
BarometerRaw="$(grep -A1 "Barometer" $inputPage | sed '1d')"
DewPointRaw="$(grep -A1 "Dewpoint" $inputPage | sed '1d')"
TemperatureRaw="$(grep "myforecast-current-sm" $inputPage)"
SkyRaw="$(grep "myforecast-current.>" $inputPage) in $1, $2"
TimeRaw="$(grep -A2 "Last update" $inputPage | sed '1,2d')"


#format raw string and output them to the user
echo "Weather Report As Of" | toilet -f pagga
echo "$TimeRaw" | sed -e 's/^[[:space:]]*//g' | sed 's/\<td\>//g' | tr -d '<>/' | sed -e 's/[[:space:]]*$//g' | toilet -f pagga
echo "$SkyRaw" | sed -e 's/^[[:space:]]*//g' | sed 's/.*current//g' | tr -d '<>/p\"' | toilet -w $width -f pagga
echo "Temperature of $(echo "$TemperatureRaw" | sed 's/.*sm//g' | tr -d 'p<>deg&/\"' | tr ';' ' ')" | toilet -f pagga
echo "Humidity:    " | tr -d '\n'
echo "$HumidityRaw" | sed -e 's/^[[:space:]]*//g' | tr -d 'td<>/'
echo "Wind Speed:  " | tr -d '\n'
echo "$WindSpeedRaw" | sed -e 's/^[[:space:]]*//g' | tr -d 'td<>/'
echo "Barometer:   " | tr -d '\n'
echo "$BarometerRaw" | sed -e 's/^[[:space:]]*//g' | tr -d 'td<>/'
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
forecastWhole="$(cat $inputPage | tr '\n' ' ' | grep -o "detailed-forecast-body.*" | grep -o ".*<\!-- /Detailed Forecast" | sed 's/row row-odd row-forecast\|row row-even row-forecast/\n/g' | sed '1d' | tr -d '\"')"
echo "$seperatorB"

for i in {1..9} #each iteration processes and prints out one time periods forecast.
do
	period="p$i.txt"
	description="d$i.txt"
	sedLine="$(echo "$i p" | tr -d ' ')"
	echo "$forecastWhole" | sed -n "$sedLine" | grep -o "<b>[a-zA-Z ]*" | sed -n '1p' | sed 's/<b>//g' | toilet -f future > $period
	length=$(wc -L $period | sed 's/ .*//g')
	let "size = width - length - 1"
	description0=$(echo "$forecastWhole" | sed -n "$sedLine" | sed 's/.*col-sm-10 forecast-text>//g' | sed 's/<.*//g' | sed 's/\%/ percent/g' | fold -s -w $size)
	description1=$(echo "$description0" | sed -E -e "s/(sunny)/$YELLOW:\1$NC/g" | tr -d ":")
	description2=$(echo "$description1" | sed -E -e "s/(rain|snow|rainfall)/$CYAN:\1$NC/g" | tr -d ":")
	description3=$(echo "$description2" | sed -E -e "s/(hot|warm)/$RED:\1$NC/g" | tr -d ":")
	description4=$(echo "$description3" | sed -E -e "s/(cold|cool|chilly)/$BLUE:\1$NC/g" | tr -d ":")
	echo "$description4" | sed -E -e "s/(gusts|wind|cloudy)/$GREEN:\1$NC/g" | tr -d ":" > $description
	output=$(paste $period $description | tr '\t' ' ')
	printf "$output\n"
	echo "$seperatorA"
	rm $period $description
done


#clean up when we are done
rm $inputPage
