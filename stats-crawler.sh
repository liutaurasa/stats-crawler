#!/bin/bash


SKL_TEAM_STATS_URL='https://www.sostineskl.lt/komandos/index.php?act=f&t=team_stat&lid=1&tid=171&s=2021&_=1636974640456'
SKL_PLAYER_STATS_URL='https://www.sostineskl.lt/komandos/index.php?act=f&t=player_stat&pid=${id}&s=2021&lid=1&tid=171'
RKL_TEAM_STATS_URL='https://www.rkl.lt/komandos/index.php?act=f&t=team_stat&lid=1&tid=2494&s=2021&_=1636961238990'
RKL_PLAYER_STATS_URL='https://www.rkl.lt/komandos/index.php?act=f&t=player_stat&lid=1&tid=2494&s=2021&pid=${id}&sf=&_=1636958151607'

case $1 in
    '--skl')
        TEAM_STATS_URL=${SKL_TEAM_STATS_URL}
        PLAYER_STATS_URL=${SKL_PLAYER_STATS_URL};;
    '--rkl')
        TEAM_STATS_URL=${RKL_TEAM_STATS_URL}
        PLAYER_STATS_URL=${RKL_PLAYER_STATS_URL};;
    *)
        echo "Provide --skl or --rkl"; exit 1;;
esac

TEAM_STATS="$(curl "${TEAM_STATS_URL}" 2>/dev/null)"

echo "${TEAM_STATS}" | html2text --ignore-links --pad-tables --ignore-emphasis -b 0 --single-line-break

for ID in $(echo "${TEAM_STATS}" | grep -o 'id=\"p_.*\"' | tr -d 'p_'); do
    eval ${ID}
    _URL="$(eval echo \"${PLAYER_STATS_URL}\")"
    curl "${_URL}" 2>/dev/null | \
        html2text --ignore-links --pad-tables --ignore-emphasis -b 0 --single-line-break | \
            grep -v -e 'nežaidė' -e '^×$' -e '### Statistika (2021)' | \
            sed -e 's/#### .* \/ //' | \
            awk -F'|' '
                {
                    if($0~/^$/) next
                    if($1~/^---/) separator_line=$0
                    if($1~/^2021/){
                        games+=1;
                        date_w=length($1)
                        rival_w=length($2)
                        time_w=length($3)-2
                        points_w=length($4)-2
                        two_p_w=length($5)-2
                        three_p_w=length($6)-2
                        free_t_w=length($7)-2
                        split($3,seconds,":"); total_seconds+=(seconds[1]*60 + seconds[2]);
                        points=$4; total_points+=points;
                        split($5,two_," "); split(two_[1],two_p,"/"); total_two_m+=two_p[1]; total_two_a+=two_p[2]
                        split($6,three_," "); split(three_[1],three_p,"/"); total_three_m+=three_p[1]; total_three_a+=three_p[2]
                        split($7,free_," "); split(free_[1],free_t,"/"); total_free_m+=free_t[1]; total_free_a+=free_t[2]
                    };
                    OFS="|"; print $0
                }
                END {
                    total_minutes=total_seconds/60
                    avg_seconds=total_seconds/games
                    avg_time=int(avg_seconds/60)":"int(avg_seconds%60)
                    avg_points=total_points/games
                    if (total_two_a + 0 != 0) avg_two=int(total_two_m/total_two_a*100)
                    if (total_three_a + 0 != 0) avg_three=int(total_three_m/total_three_a*100)
                    if (total_free_a + 0 != 0) avg_free=int(total_free_m/total_free_a*100)
                    print separator_line
                    printf "%-"date_w+rival_w"s | %-"time_w"s | %-"points_w".1f | %-"two_p_w"s | %-"three_p_w"s | %-"free_t_w"s | \n", "Averages ("games" games)", avg_time, avg_points, total_two_m"/"total_two_a" ("avg_two"%)", total_three_m"/"total_three_a" ("avg_three"%)", total_free_m"/"total_free_a" ("avg_free"%)";
                    printf "%-"date_w+rival_w"s | %-"time_w".2f | %-"points_w".1f | %-"two_p_w".2f | %-"three_p_w".2f | %-"free_t_w".2f | ",
                        "Per 40 mins played",
                        total_minutes,
                        total_points/total_minutes*40,
                        total_two_m/total_minutes*40,
                        total_three_m/total_minutes*40,
                        total_free_m/total_minutes*40;
                    print "\n"
                }
            '   
done
