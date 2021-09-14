CONKY_PATH=~/.config/conky
SPOTIFY_PATH=$CONKY_PATH/spotify
id_current=$(cat $SPOTIFY_PATH/id.txt)
id_new=`$SPOTIFY_PATH/id.sh`
cover=
imgurl=

if [ "$id_new" != "$id_current" ]; then

	cover=`ls $SPOTIFY_PATH/covers | grep $id_new`

	if [ "$cover" == "" ]; then

	    imgurl=`$SPOTIFY_PATH/imgurl.sh $id_new`
	    wget -q -O $SPOTIFY_PATH/covers/$id_new.jpg $imgurl &> /dev/null
	    touch $SPOTIFY_PATH/covers/$id_new.jpg
		# clean up covers folder, keeping only the latest X amount, in below example it is 10
	    #rm -f `ls -t ~/.conky/conky-spotify/covers/* | awk 'NR>10'`
	    rm -f wget-log #wget-logs are accumulated otherwise
	    cover=`ls $SPOTIFY_PATH/covers | grep $id_new`
	fi

	if [ "$cover" != "" ]; then
		cp $SPOTIFY_PATH/covers/$cover $SPOTIFY_PATH/cover.jpg
	else
		cp $SPOTIFY_PATH/empty.jpg $SPOTIFY_PATH/cover.jpg
	fi

	echo $id_new > $SPOTIFY_PATH/id.txt
fi
