#!/bin/bash
#this file put in the dir:bc_pbft,bc_raft,bc_rpbft,so you need pre-make above dir

: '
./deploy_addNode.sh 127.0.0.1 30300 20200 8545 pbft 


./deploy_addNode.sh 127.0.0.1 30300 20200 8545 raft 


./deploy_addNode.sh 127.0.0.1 30300 20200 8545 rpbft 

./generator-A/nodeA5/start_all.sh 
./generator-A/nodeA10/start_all.sh 
./generator-A/nodeA15/start_all.sh 
./generator-A/nodeA20/start_all.sh 

./generator-A/nodeA5/stop_all.sh 
./generator-A/nodeA10/stop_all.sh 
./generator-A/nodeA15/stop_all.sh 
./generator-A/nodeA20/stop_all.sh 

cd ./generator_A 
tail -f ./node*/node*/log/log* | grep +++

'
IP=$1   #192.168.188.111
P2P_PORT=$2  #30300
CHANNEL_PORT=$3  #20200
RPC_PORT=$4  #8545
CONSENSUS_TYPE=$5
WORK_DIR=$PWD

function catToDepIni(){
#$1(parameter):1~4(the group number of 5 nodes)   
cat > ./conf/node_deployment.ini << EOF
[group]
group_id=1
EOF
	#i:0~4  port:$[$P2P_PORT+($1-1)*5+$i]
	for((i=0;i<5;i++))
	do
cat >> ./conf/node_deployment.ini << EOF
[node$i]
p2p_ip=$IP
rpc_ip=$IP
channel_ip=0.0.0.0
p2p_listen_port=$[$P2P_PORT+($1-1)*5+$i]
channel_listen_port=$[$CHANNEL_PORT+($1-1)*5+$i]
jsonrpc_listen_port=$[$RPC_PORT+($1-1)*5+$i]
EOF
	done
}


cd $WORK_DIR && git clone https://github.com/FISCO-BCOS/generator.git
cd $WORK_DIR/generator && bash ./scripts/install.sh
echo "`./generator -h`"

#拉取最新fisco-bcos二进制文件到meta中
./generator --download_fisco ./meta
echo "`./meta/fisco-bcos -v`"


#联盟链初始化
cp -r $WORK_DIR/generator $WORK_DIR/generator-A

cd $WORK_DIR/generator
./generator --generate_chain_certificate ./dir_chain_ca

./generator --generate_agency_certificate ./dir_agency_ca ./dir_chain_ca agencyA
cp ./dir_agency_ca/agencyA/* $WORK_DIR/generator-A/meta/

#机构A修改配置文件
cd $WORK_DIR/generator-A
catToDepIni 1

#机构A生成并发送节点信息
cd $WORK_DIR/generator-A
./generator --generate_all_certificates ./agencyA_node_info
cp ./agencyA_node_info/peers.txt $WORK_DIR/generator-A/meta/peersA.txt

#机构A生成群组1创世区块
cd $WORK_DIR/generator-A
cat > ./conf/group_genesis.ini << EOF
[group]
group_id=1
[nodes]
node0=$IP:$P2P_PORT
node1=$IP:$[$P2P_PORT+1]
node2=$IP:$[$P2P_PORT+2]
node3=$IP:$[$P2P_PORT+3]
node4=$IP:$[$P2P_PORT+4]
EOF

./generator --create_group_genesis ./group
#CONSENSUS_TYPE:pbft raft rpbft  
#对两个文件（~/generator-A/group/group.1.genesis和~/generator-A/meta/group.1.genesis）进行修改
if [ $CONSENSUS_TYPE = "raft" ]
then
	#modify 
	sed -i "s/pbft/raft/g" $WORK_DIR/generator-A/group/group.1.genesis
	sed -i "s/pbft/raft/g" $WORK_DIR/generator-A/meta/group.1.genesis
elif [ $CONSENSUS_TYPE = "rpbft" ]
then
	#modify 
	sed -i "s/pbft/rpbft/g" $WORK_DIR/generator-A/group/group.1.genesis
	sed -i "s/pbft/rpbft/g" $WORK_DIR/generator-A/meta/group.1.genesis

	#modify nu 10
	sed -i '10c epoch_sealer_num = 4' $WORK_DIR/generator-A/group/group.1.genesis
	sed -i '10c epoch_sealer_num = 4' $WORK_DIR/generator-A/meta/group.1.genesis
	
fi


#机构A生成所属节点组1 nodes are in:./nodeA5
cd $WORK_DIR/generator-A
./generator --build_install_package ./meta/peersA.txt ./nodeA5


$NUMBER_OF_NODE
#配置控制台,in and exit!!!!!
cd $WORK_DIR/generator-A
./generator --download_console ./ --cdn

cd $WORK_DIR/generator-A/console && bash ./start.sh 1  #wait














#—机构A扩容节点加入群组1   nodes are in:./nodeA10
cd $WORK_DIR/generator-A
catToDepIni 2
./generator --generate_all_certificates ./agencyA_node_info_new10
cat ./agencyA_node_info/peers.txt >> ./meta/peersA.txt
./generator --build_install_package ./meta/peersA.txt ./nodeA10

#—机构A扩容节点加入群组1   nodes are in:./nodeA15
cd $WORK_DIR/generator-A
catToDepIni 3
./generator --generate_all_certificates ./agencyA_node_info_new15
cat ./agencyA_node_info/peers.txt >> ./meta/peersA.txt
./generator --build_install_package ./meta/peersA.txt ./nodeA15

#—机构A扩容节点加入群组1   nodes are in:./nodeA20
cd $WORK_DIR/generator-A
catToDepIni 4
./generator --generate_all_certificates ./agencyA_node_info_new20
cat ./agencyA_node_info/peers.txt >> ./meta/peersA.txt
./generator --build_install_package ./meta/peersA.txt ./nodeA20


















