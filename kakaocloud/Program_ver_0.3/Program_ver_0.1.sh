#/bin/bash
#실행시 ./Program으로 실행시키면 -e가 보이지 않습니다.
clear

#######↓ 개인 사용자 수정필요  ######
#ip 목록들 (반드시 수정 필요)
ip1="172.30.3.230"   #각 VM입력표시
ip2="172.30.1.210"
ip3="172.30.3.120"
ip4="172.30.1.18"
ip5="" # 미정
#ip99="127.0.0.1" loopback
filepath="~/lucas/pem/TechCS.pem" # pem파일 path
token="gAAAAABjKnljpJaVHRPNQqalNzovp9YOqrFvj_ez5LCd_x-o0WLaeSi5pVlm1MJFTjb3kRPUnP7TMtdiY9bJkqFSup3lpuJujfVftiz7CXlkHb2s_qDUJFYDc8ZTQN061dKbXNuDVEmTK4drXU-rlvDax2cjxbr8DB7Q_7THdMq4UxEMl2cZGPdCi6fRHrAk0gr0ZfO4IQA9" # object-storage-token 알게되면 입력  - 초기상태 : 0


menu_VM_Select(){
	echo -e "사용하기 위한 VM을 선택해주세요.\n
	1.vm-lucas-dev-k8s-master-1
	2.vm-lucas-dev-k8s-worker-1
	3.vm-lucas-dev-k8s-worker-2
	4.vm-lucas-test
	5.미정\n"
	#99. LoopBack
	menu_Select
}

menu_VM_IP(){
	case $select in
		1) ip=$ip1;;
		2) ip=$ip2;;
		3) ip=$ip3;;
		4) ip=$ip4;;
		#5) ip=$ip5;;
		#6) ip=$ip6;;
		#99) ip=$ip99;;
		*) clear
		   echo "잘못된 입력 또는 존재하지 않는 VM입니다. 죄송합니다."; exit 0;;
	esac
}



########↓ 변수 선언 #########  (여기서 부터는 건드릴 필요 X)
ex=1
num=0
apitokenserver="https://iam.kakaoi.io/identity/v3/auth/tokens"
objectStorageServer="https://objectstorage.kr-central-1.kakaoi.io/v1_ext/bucket"
bucketType="hot"
encryption="true"
bucketName=""

######↓ 추가 기능 함수 ######
menu_Text(){
	echo -e "	0. 종료
	1. SSH (Ping 가능해야 연결)
	2. PING(Check)
	3. CURL
	4. SCP
	5. API 확인
	6. Object Storage bucket
	7. 미정\n"
}

menu_Check(){
	clear
	case $1 in
		0) echo "프로그램을 종료합니다. 수고하세요!";;
		1) scp_Connect;;
		2) ping_Check;;
		3) curl_Check;;
		4) scp_Work;;
		5) api_Check;;
		6) bucket_Work;;
		7) echo "아직 미구현입니다. 죄송합니다.";;
		*) echo "잘못된 입력입니다. 죄송합니다."
	esac
}

menu_ObjectStorage(){
	echo "Object Storage 사용을 시작합니다."
	echo -e "\n어떤 작업을 원하시나요? \n"
	echo -e "	1. 버킷 생성
	2. 버킷 상세 조회
	3. 버킷 삭제
	4. 폴더 생성
	5. 폴더 삭제
	6. 파일들 목록 조회
	7. 파일 생성 및 업로드
	8. 파일 다운로드
	9. 파일 삭제\n"
}
scp_Connect(){
	menu_VM_Select
	menu_VM_IP
	clear
	echo -e "\n연결 확인중에 있습니다. 잠시만 기다려주세요\n";
	connect_Check
	if [ $? -gt 1 ]
	then
		clear
		echo "죄송합니다. 현재 연결이 되지 않습니다. 다시 한번 확인 부탁드립니다. 감사합니다"
	else
		echo "<연결 완료>"
		sleep 3
		clear
		ssh -i $filepath ubuntu@$ip
	fi
}

connect_Check(){
	echo "연결 확인"
	while [ $ex != 0 ]
	do
		ping $ip -p 22 -c 3 > /dev/null
		ex=$?
		num=$((num+1))
		if [ $num -gt 1 ]
		then
			break
		fi
	done
	return $num
}

ping_Check(){
	menu_VM_Select
	menu_VM_IP
	clear
	echo -e "\nPING 체크를 시작합니다.\n";
	echo "<핑 체크 현황>"
	while [ $ex != 0 ]
	do
		ping $ip -p 22 -c 5 # > /dev/null
		ex=$?
		num=$((num+1))
		if [ $num -gt 1 ]
		then  #변환
			break;
		fi
	done
	if [ $num -gt 1 ]
	then
		echo -e "\n연결이 되지 않습니다. 핑 체크에 실패하였습니다. 감사합니다"
	else
		echo -e "\n핑 정상적으로 확인되었습니다. 감사합니다"
	fi
}

curl_Check(){
	menu_VM_Select
	menu_VM_IP
	clear
	echo "해당 VM에 Curl를 확인합니다."
	echo -e "해당 결과값 창\n"
	curl -v $ip
	echo -e "\n테스트 완료했습니다. 감사합니다.\n"
}

scp_Work(){
	menu_VM_Select
	menu_VM_IP
	clear
	echo -e "먼저 연결확인을 진행합니다.\n"
	connect_Check
	if [ $? -gt 1 ]
	then
		clear
		echo "죄송합니다. 현재 연결이 되지 않습니다. 다시 한번 확인 부탁드립니다. 감사합니다"
	else
		echo -e "<연결 완료>\n"
		echo -e "어떤 SCP 작업을 원하시나요?\n"
		echo -e "1. 업로드
2. 다운로드\n"
		menu_Select
		clear
		case $select in
			1) echo -e "SCP 업로드를 진행합니다.\n"
				echo -e "어떤 파일을 올리시겠습니까? (현재 디렉터리 기준)\n"
				ls -l
				echo -e "\n파일 또는 디렉터리명 입력(해당 내의 파일들이 모두 전송) : "
				read filename
				clear
				echo "< 전송 작업 중 >"
				scp -i $filepath -r ./$filename ubuntu@$ip:/home/ubuntu/$filename
				if [ $? -eq 0 ]
				then
					echo -e "\n정상적으로 완료되었습니다. 감사합니다 "
				else
					echo -e "\n없는 파일 또는 폴더이거나 다른원인에 의해 실패하였습니다. 죄송합니다"
				fi;;
			2) echo -e "SCP 다운로드를 진행합니다.\n"
				echo "어떤 파일을 다운로드 하시겠습니까? (다운로드 할 폴더의 이름명)"
           			echo "파일 또는 디렉터리명 입력(해당 내의 파일들이 모두 전송) : "
           			read filename
				clear
				echo "< 전송 작업 중 >"
				scp -i $filepath -r ubuntu@$ip:/home/ubuntu/$filename ./$filename
				if [ $? -eq 0 ]
				then
					echo -e "\n정상적으로 완료되었습니다. 감사합니다 "
				else
					echo -e "\n없는 파일 또는 폴더이거나 다른원인에 의해 실패하였습니다. 죄송합니다"
				fi;;
			*) echo "잘못된 입력입니다. 죄송합니다"
			   exit 0;;
		esac
	fi
}

api_Check(){
	echo "어떤 API 작업을 원하시나요?"
	echo -e "1. Object API 인증 토큰 확인
2. 미구현\n"
	menu_Select
	clear
	case $select in
		1) echo "API 인증 토큰 발급을 시작합니다."
			echo "KIC 사용자 설정의 사용자 액세스 키 ID를 입력해주세요. "
			read accesskey
			echo "KIC 사용자 설정의 사용자 보안 키를 입력해주세요. "
			read hiddenkey
			clear
			echo -e "확인중입니다. 잠시만 기다려주세요\n"
			curl -v -X POST $apitokenserver -H 'Content-type: application/json' --data '{ "auth": { "identity": { "methods": [ "application_credential" ], "application_credential": { "id": "'"${accesskey}"'","secret":"'"${hiddenkey}"'"}}}}' 2>&1 | grep x-subject-token
			if [ $? -eq 0 ]
			then
				echo -e "\n정상적으로 완료되었습니다. 감사합니다."
				echo "토큰을 복사부탁드립니다."
			else
				echo -e "\n다른원인에 의해 실패하였습니다. 죄송합니다"
			fi;;
		2) echo "미구현입니다. 죄송합니다"
			exit 0;;
		*) echo "잘못된 입력입니다. 죄송합니다"
			exit 0;;
	esac
}
bucket_Work(){
	if [ $token -eq 0 ]
	then
		echo -e "죄송합니다. \n현재 스크립트 상으로는 토큰이 준비되어 있지 않습니다.\n"
		echo -e "\n토큰을 임시 등록하시겠습니까?"
		echo -e "1. 등록함    2. 등록하지 않음\n"
		menu_Select
		clear
		case $select in
			1) echo -e "임시 등록 하겠습니다.\n"
				echo "토큰값을 입력해주세요"
				read token
				echo -e "\n토큰 입력이 완료되었습니다. 감사합니다.";;
			2) echo "등록하지 않으시면 사용이 불가합니다. 죄송합니다. "
				echo "토큰 값 확인 이후 스크립트 수정 또는 임시 등록 부탁드립니다. 감사합니다"
				exit 0;;
			*) echo "잘못된 입력입니다. 죄송합니다"
				exit 0;;
		esac
	fi
	clear
	menu_ObjectStorage
	menu_Select
	ObjectStorage_Script $select

}

ObjectStorage_Script(){
	clear
	case $1 in
		1) echo "Bucket 생성을 시작합니다."
			echo -e "먼저 Bucket의 Type을 정해주세요\n"
			echo -e "1. HOT\n2. Cold (지원예정)\n"
			menu_Select
			case $select in
				1) bucketType="hot";;
				2) bucketType="cold";;
				*) echo "잘못된 입력입니다. 죄송합니다."
					exit 0;;
			esac
			clear
			echo "암호화를 하시겠습니까?(대문자 X)"
			echo -e "y. 암호화 사용\nn. 암호화 사용 안함\n"
			menu_Select
                        case $select in
                                y) encryption="true";;
                                n) encryption="false";;
                                *) echo "잘못된 입력입니다. 죄송합니다."
                                        exit 0;;
                        esac
			clear
			echo "버킷의 이름을 설정해주세요.(무조건 넣어주세요)(중복확인은 아직 불가)"
			echo "영어, 숫자, 대시(-)를 입력해 주세요. (4~40자)(대문자 가능)"
			read bucket
			bucketName=${bucket,,}
			clear
			echo -e "버킷 생성중입니다. 잠시만 기다려주세요\n"
			sleep 3
			curl --location --request PUT ''$objectStorageServer'' --header 'X-Auth-Token:'$token'' --header 'Content-Type: application/json' --data-raw '{ "name": "'"$bucketName"'", "type": "'"$bucketType"'","use_encryption":'$encryption'}' | jq -r
			if [ $? -eq 0 ]; then
				echo -e "\n\n정상적으로 생성이 완료되었습니다."
			else
				echo -e "\n\n알수 없는 이유로 인해 실패하였습니다. 죄송합니다"
			fi;;
		2) echo "Bucket 상세 조회를 시작합니다."
			echo -e "먼저 현재 존재하고 있는 Bucket 목록을 조회합니다. (최대 50개)\n"
		       	sleep 1
			curl --location --request GET ''$objectStorageServer'?limit=50' --header 'X-Auth-Token:'$token'' | jq -r .items | grep name
			echo -e "\n상세 정보 조회를 하고 싶은 Bucket를 입력해주세요.(이메일 주소 X)"
			read bucket
			clear
			echo -e "버킷 조회중입니다. 잠시만 기다려주세요\n"
			sleep 3
			curl --location --request GET ''$objectStorageServer'/'$bucket'' --header 'X-Auth-Token:'$token'' | jq -r
			if [ $? -eq 0 ]; then
                                echo -e "\n\n정상적으로 조회가 완료되었습니다."
                        else
                                echo -e "\n\n존재하지 않는 이름으로 인해 실패하였습니다. 죄송합니다"
                        fi;;
		3) echo "Bucket 삭제를 시작합니다. (신중하게 생각해주세요)"
			echo -e "먼저 현재 존재하고 있는 Bucket 목록을 조회합니다. (최대 50개)\n"
                        sleep 1
                        curl --location --request GET ''$objectStorageServer'?limit=50' --header 'X-Auth-Token:'$token'' | jq -r .items | grep name
                        echo -e "\n삭제를 하고 싶은 Bucket를 입력해주세요.(이메일 주소 X)"
                        read bucket
                        clear
			echo -e "\n정말로 삭제하시겠습니까? 복구가 불가합니다.(대문자X)"
			echo -e "\ny. 삭제합니다.\nn. 삭제하지 않습니다.\n"
			menu_Select
			clear
			case $select in
				y) echo -e "버킷 삭제가 진행 중입니다. 잠시만 기다려주세요"
					sleep 3
					status=$(curl --location --request DELETE ''$objectStorageServer'/'$bucket'' --header 'X-Auth-Token:'$token'')
					echo "$status";; #누가 수정좀 도와줘
					#if [ $status -eq "Not Found Error" ]; then
					#	echo -e "\n\n삭제가 정상적으로 완료되었습니다."
					#else
					#	echo -e "\n\n존재하지 않는 이름으로 인해 실패하였습니다. 죄송합니다"
					#fi;;
				n) echo -e "\n버킷 삭제를 중단하였습니다. 프로그램을 종료합니다.";;
			esac;;
		4) echo "폴더 생성을 시작합니다."
		        echo -e "먼저 현재 존재하고 있는 Bucket 목록을 조회합니다. (최대 50개)\n"
                        sleep 1
                        curl --location --request GET ''$objectStorageServer'?limit=50' --header 'X-Auth-Token:'$token'' | jq -r .items | grep name
                        echo -e "\n어느 Bucket을 이용하시겠습니까?(이메일 주소 X)"
                        read bucket
                        clear
			echo "폴더의 이름을 설정해주세요(무조건 넣어주세요)(중복확인은 아직 불가)"
			echo "영어, 숫자, 대시(-)를 입력해 주세요. (4~40자)(대문자 가능)"
			read bucket;;
		*) echo "잘못된 입력입니다. 죄송합니다.";;
	esac
}
main_Text(){
	echo "###### Tech CS Program #########"
	echo "###### 버그제보 : lucas.1004####"
	echo -e "어떤 작업을 원하시나요?\n"
}

menu_Select(){
	echo "값을 입력해주세요 : "
	read select;
}

###메인 함수 ↓ ###
main_Function(){

	main_Text
	menu_Text
	menu_Select
	menu_Check $select

}
main_Function


---
#
listnum<${#vm_name[@]};
echo -e \
"Host bastion\n  HostName $hostip\n  User ubuntu\n  ForwardAgent yes\n  IdentityFile $gwkeylo\n\nHost staging ig\n  HostName $coip\n  User ubuntu\n  IdentityFile $vmkeylo \n  ProxyCommand ssh bastion -W %h:%p" > ~/.ssh/config
ssh staging;;
scp -i $vmkeylo -r ~/Downloads/${filename} staging:/home/ubuntu/
