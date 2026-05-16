#!/bin/bash

versao='Version: 1.02 $ [Abr 24 2026 15:00:00]';
if [ $1 = '-V' ]; then
        echo "Copyright (C) 2020-2026 Rematec";
        echo "clienteRede.sh - Gestao de Campanhas Rede";
        echo "$versao";
        exit;
fi
function log(){
        date +"%Y-%m-%d %H:%M:%S:%3N -> $* " >> ${logdir}
}
function sair(){
        log "Function sair."
        opcaoSair=$1;
        log "-------------------------------------------------------------------- Fim"
        if [ "${opcaoSair}" == "" ];then
                echo "ERROR= "
                echo "BYE 1";
        else
                [ "${mensagemConsulta}" == "" ] && mensagemConsulta="Operacao cancelada.";
                echo "ERROR=${mensagemConsulta}"
                echo "BYE ${opcaoSair}";
        fi
        exit 0;
}
function limpa_ateos(){

        if [ -f "/var/venditor/WRK/AT_EOS.dat" ];then
                exec_ateos=`cat /var/venditor/WRK/AT_EOS.dat | grep 'clienteRede.sh' | wc -l`
                if [ $exec_ateos -gt 0 ];then
                        sed -i '/clienteRede.sh/d' /var/venditor/WRK/AT_EOS.dat;
                        log "LIMPA_ATEOS -> Apagando agendamento clienteRede.sh existene no AT_EOS.dat.";
                fi
        fi
}
function ateos(){

        limpa_ateos
        echo "AT_EOS SHELL ./clienteRede.sh --action=clear";
        echo "AT_VOID27 ./clienteRede.sh --action=clear";
        log "ATEOS -> AT_EOS SHELL ./clienteRede.sh --action=clear";
}
function evaluate(){
        echo "EVALUATE {EMPORIUM_IP}"
        read servidor
        echo "EVALUATE {EMPORIUM_PORT}"
        read port
        echo "EVALUATE {LOJA}"
        read store
        echo "EVALUATE {CAIXA}"
        read pos
        echo "EVALUATE {CUPOM}"
        read cupom
        echo "EVALUATE {STATUS}"
        read status
        echo "EVALUATE {STATE}"
        read state
        echo "EVALUATE {SRV_CRM}";
        read server_crm
        echo "EVALUATE {MAXTIMEOUT}"
        read max
        [[ ${max} == "MAXTIMEOUT" || ${max} -eq 0 ]] && max=30;
        echo "EVALUATE {MINTIMEOUT}"
        read min
        [[ ${min} == "MINTIMEOUT" || ${min} -eq 0 ]] && min=5;

        logdir="/var/log/clienteRede.log";
        OBLATA="/var/venditor/WRK/OBLATA.dat";
        GERENCIAL="/var/venditor/WRK/EXTRA.dat";
        varDoc="/var/venditor/WRK/VarDoc.txt";
	prefixoGrupo="GRUPO_REDE";
        Logrotate=`cat /etc/logrotate.d/venditor | grep clienteRede | wc -l`
        [ $Logrotate -eq 0 ] && sed -i '1i\/var\/log\/clienteRede*.log' /etc/logrotate.d/venditor;
}
function validaCpf(){
        log "Function validaCpf";
        # se for cst_id for igual a 11 caracteres considera CPF
        valid=0
        len=${#cst_id}
        if [ $len == 11 ]; then
                if [[ ${cst_id} -eq 00000000000 || ${cst_id} -eq 11111111111 || ${cst_id} -eq 22222222222 || ${cst_id} -eq 33333333333 || ${cst_id} -eq 44444444444 || ${cst_id} -eq 55555555555 || ${cst_id} -eq 66666666666 || ${cst_id} -eq 77777777777 || ${cst_id} -eq 88888888888 || ${cst_id} -eq 99999999999 ]];then
                        valid=0;
                else
                        mulUm=1
                        DigUm=0
                        for digito in {1..9}; do
                                let DigUm+=$(($(echo $cst_id | cut -c$digito) * $mulUm))
                                mulUm=$(echo $(($mulUm+1)))
                        done

                        restUm=$(($DigUm%11))
                        [ $restUm -gt 9 ] && primeiroDig=0 || primeiroDig=$restUm;

                        mulDois=0
                        DigDois=0
                        for digitonew in {1..10}; do
                                let DigDois+=$(($(echo $cst_id | cut -c$digitonew) * $mulDois))
                                mulDois=$(echo $(($mulDois+1)))
                        done
                        restDois=$(($DigDois%11))
                        [ $restDois -gt 9 ] && segundoDig=0 || segundoDig=$restDois;
                        if [ $(echo $cst_id | cut -c10) == $primeiroDig -a  $(echo $cst_id | cut -c11) == $segundoDig ]; then
                                valid=1;
                        fi
                fi
        fi
        if [ $len == 14 ]; then
                mulUm=6
                DigUm=0
                for digito in {1..12}; do
                        let DigUm+=$(($(echo $cst_id | cut -c$digito) * $mulUm))
                        mulUm=$(echo $(($mulUm+1)))
                        [ $mulUm -eq 10 ] && mulUm=2;
                done

                restUm=$(($DigUm%11))
                [ $restUm -gt 9 ] && primeiroDig=0 || primeiroDig=$restUm;

                mulDois=5
                DigDois=0
                for digitonew in {1..13}; do
                        let DigDois+=$(($(echo $cst_id | cut -c$digitonew) * $mulDois))
                        mulDois=$(echo $(($mulDois+1)))
                        [ $mulDois -eq 10 ] && mulDois=2;
                done
                restDois=$(($DigDois%11))
                [ $restDois -gt 9 ] && segundoDig=0 || segundoDig=$restDois;

                if [ $(echo $cst_id | cut -c13) == $primeiroDig -a  $(echo $cst_id | cut -c14) == $segundoDig ]; then
                        valid=1;
                fi
        fi
        if [ $valid -eq 0 ]; then
                [[ -f ${varDoc} && ! -s ${varDoc} ]] && rm ${varDoc};
                echo "ACCEPT TITLE Identificacao Invalida!";
                echo "ACCEPT PROMPT Tecle ESC"
                echo "ACCEPT READ";
                read tecla
                echo "COMMAND 111 api";
                read cmd_rsl
                echo "COMMAND 14 api";
                read cmd_rsl
        fi
}
function PreCadastro(){
	log "Function PreCadastro.";

	echo "EVALUATE {MAXTIMEOUT}"
	read max
	[[ ${max} == "MAXTIMEOUT" || ${max} -eq 0 ]] && max=30;

	echo "EVALUATE {MINTIMEOUT}"
	read min
	[[ ${min} == "MINTIMEOUT" || ${min} -eq 0 ]] && min=2;

	echo "EVALUATE {CPF_PRE_CADASTRO}";
	read cpfPreCadastro

	echo "EVALUATE {CELULAR_PRE_CADASTRO}";
	read celularPreCadastro

	echo "EVALUATE {SRV_CRM}";
	read server_crm
	
	data=$(echo -e "{\"cpf\":\""${cpfPreCadastro}"\", \"celular\":\""${celularPreCadastro}"\"}");

	endPoint=$server_crm"customer";
	objeto="RetornoCrm.json";

	[ -f ${objeto} ] && rm ${objeto};	
	
	log "curl --header 'Content-Type: application/json' --data '${data}' -w '%{http_code}\n' --connect-timeout ${min} --max-time ${max} -X POST --location ${endPoint} --output ${objeto} --silent";
	OUTPUT=$(curl --header "Content-Type: application/json" --data "${data}" -w "%{http_code}\n" --connect-timeout ${min} --max-time ${max} -X POST --location ${endPoint} --output ${objeto} --silent );
	
	log "CODIGO DO RETORNO: [${OUTPUT}]";
	retorno=$(cat ${objeto});
	log "RETORNO: [${retorno}]";

	if [ "${OUTPUT}" != "200" ];then
		log "Pre cadastro contigencia xml."
		confirmacao="<?xml version='1.0' standalone='yes'?><TRANSACTION><CODE>7</CODE><WHAT>2</WHAT><SHELL_COMMAND>curl --header 'Content-Type: application/json' --data '${data}' -w '%{http_code}\n' --connect-timeout ${min} --max-time ${max} -X POST --location ${endPoint} --silent</SHELL_COMMAND></TRANSACTION>";
		log "[${confirmacao}]";
		echo "${confirmacao}" >> /var/venditor/SND/PRE_CADASTRO_CONT_${cpfPreCadastro}.xml;
	fi

	echo "CPF_PRE_CADASTRO= ";
	echo "CELULAR_PRE_CADASTRO= ";
	
	sair;
}	
function getToken(){
	log "Function checkToken.";

	if [ ${presencaPinPad} -eq 1 ];then
		echo "ACCEPT PIN_TYPE_MSG 6";
		echo "ACCEPT PIN_MIN_FIELD 6";
		echo "ACCEPT PIN_MAX_FIELD 6";
		echo "ACCEPT TITLE CLIENTE (PINPAD) - Digite o";
		echo "ACCEPT PROMPT codigo enviado para seu celular";
		echo "ACCEPT PIN_MSG 010606Informe o token                 OK?";
		echo "ACCEPT GENERIC_PINDATA";
		read token;
	else
		echo "ACCEPT TITLE Digite o codigo enviado seu celular";
		echo "ACCEPT PROMPT Codigo:";
		echo "ACCEPT READ";
		read token;
	fi

	checkToken
}
function checkToken(){
	log "Function checkToken.";
	if [ "${newToken}" != "${token}" ];then

		echo "ACCEPT YESNO Reenviar Codigo para validacao?"
		read yesno

		if [ ${yesno} -eq 1 ];then
			attempt=2;
			sendMessage;
			getToken;
		else
			echo "ACCEPT YESNO Codigo Invalido, Tentar Novamente?"
			read yesno
			[ ${yesno} -eq 1 ] && getToken;
		fi	
	else
		sendCadastro;
	fi
}
function sendMessage(){
	log "Function sendMessage.";
	data=$(echo -e "{\"destinatario\":\"""+55"${telefone}"\", \"mensagem\":\""${message}"\"}");
	objeto="RetornoSms.json";

	[ ${attempt} -eq 2 ] && data=$(echo -e "{\"id\":\""${idTransacao}"\"}");
	[ ${attempt} -eq 1 ] && endPoint=${sms_rede}"enviar" || endPoint=${sms_rede}"reenviar";

	log "curl --header 'Content-Type: application/json' --header 'x-api-key: ${xApiKey}' --header 'api-key: ${apiKey}'  --data '${data}' -w '%{http_code}\n' --connect-timeout ${min} --max-time ${max} -X POST ${endPoint} --output ${objeto} --silent";
	
	OUTPUT=$(curl --header "Content-Type: application/json" --header "x-api-key: ${xApiKey}" --header "apikey: ${apiKey}" --data "${data}" -w "%{http_code}\n" --connect-timeout ${min} --max-time ${max} -X POST --location ${endPoint} --output ${objeto} --silent);
#OUTPUT=200;
	log "Codigo Retorno -> [${OUTPUT}]";

}
function sendCadastro(){
	log "Function sendCadastro.";
	message="Acesse https://lojasrede.com.br/precadastro e complete seu cadastro";
	attempt=1;
	log "Inserindo a categoria [${categoria}]";
	echo "INSERT_CATEGORY ${categoria}";

	echo "EVALUATE {SRV_CRM}";
	read server_crm
	
	data=$(echo -e "{\"cpf\":\""${cst_id}"\", \"celular\":\""${telefone}"\"}");

	endPoint=$server_crm"customer";
	objeto="RetornoCrm.json";
	
	[ -f ${objeto} ] && rm ${objeto};	

	log "curl --header 'Content-Type: application/json' --data '${data}' -w '%{http_code}\n' --connect-timeout ${min} --max-time ${max} -X POST --location ${endPoint} --output ${objeto} --silent";
	OUTPUT=$(curl --header "Content-Type: application/json" --data "${data}" -w "%{http_code}\n" --connect-timeout ${min} --max-time ${max} -X POST --location ${endPoint} --output ${objeto} --silent);
	
	log "CODIGO DO RETORNO: [${OUTPUT}]";
	retorno=$(cat ${objeto});
	log "RETORNO: [${retorno}]";


	if [ ${OUTPUT} == "200" ];then
		echo "CPF_PRE_CADASTRO= ";
		echo "CELULAR_PRE_CADASTRO= ";
	else
		log "Agendando At_eos para envio de pre cadastro.";
		echo "CPF_PRE_CADASTRO=${cst_id}";
		echo "CELULAR_PRE_CADASTRO=${telefone}";
		echo "AT_EOS SHELL ./clienteRede.sh --action=pre-cadastro";
	fi

#	sendMessage;
}
function checkVariableNotification(){
	log "Function checkVariableNotification.";
	erroCtl=0;
	echo "EVALUATE {SMS_REDE}";
	read sms_rede

	echo "EVALUATE {API_KEY_REDE}";
	read apiKey

	echo "EVALUATE {X_API_KEY_REDE}";
	read xApiKey

	echo "EVALUATE {CATEG_PRE_CAD}";
	read categoria
	[[ "${categoria}" == "" || "${categoria}" == "CATEG_PRE_CAD" ]] && categoria=2; 
		
	if [[ "${sms_rede}" == "SMS_REDE" || "${sms_rede}" == "" ]];then
		erroVar="Variavel SMS_REDE nao definida";
		log "${erroVar}";
		echo "MESSAGE_BOX 3 0 Erro de envio^${erroVar}";
		erroCtl=1;
	       
	fi
	if [[ "${apiKey}" == "API_KEY_REDE" || "${apiKey}" == "" ]];then
		erroVar="Variavel API_KEY_REDE nao definida";
		log "${erroVar}";
		echo "MESSAGE_BOX 3 0 Erro de envio^${erroVar}";
		erroCtl=1;
		       
	fi

	if [[ "${xApiKey}" == "X_API_KEY_REDE" || "${xApiKey}" == "" ]];then
		erroVar="Variavel X_API_KEY_REDE nao definida";
		log "${erroVar}";
		echo "MESSAGE_BOX 3 0 Erro de envio^${erroVar}";
		erroCtl=1;
	fi
	[ ${erroCtl} -eq 1 ] && echo "BYE 1";
}
function sendToken(){
	log "Function informeToken.";

	checkVariableNotification;

	newToken=$(shuf -i 100000-999999 -n 1);
#	message="Lojas Rede: "${newToken}" seu codigo de verificacao para o cadastro";
	message="Lojas Rede: Use o codigo "${newToken}" para validar seu cadastro no Clube e aceitar receber promocoes e novidades. Ver regulamento:https://www.lojasrede.com.br/institucional/regulamento-clube-lojas-rede";
	attempt=1;
	sendMessage;
	if [ "${OUTPUT}" == "200" ];then
		idTransacao=$(ruby -rjson -e 'j = JSON.parse(File.read("'${objeto}'")); puts j["id"]');
		log "ID da transacao [${idTransacao}]";
	#attempt=2;
		getToken
	else
		echo "MESSAGE_BOX 3 0 Desculpe^Nao foi possivel enviar o codigo por SMS no momento.";	
	fi
}
function mobile(){
	log "Function mobile.";
	flag=0;
	acao=1;
	telefone=0;

	while [ ${flag} -eq 0 ];do
		case ${acao} in
			"1")
				echo "CLISITEF VERIFICA_PRESENCA_PINPAD";
				read presencaPinPad;
		
				log " Presenca PinPad -> [${presencaPinPad}]";
				
				if [ ${presencaPinPad} -eq 1 ];then
					echo "ACCEPT PIN_TYPE_MSG 5";
					echo "ACCEPT PIN_MIN_FIELD 14";
					echo "ACCEPT PIN_MAX_FIELD 14";
					echo "ACCEPT TITLE Digite o celular com DDD";
					echo "ACCEPT PROMPT";
					echo "ACCEPT PIN_MSG 011414DDD+Celular                     OK?";
					echo "ACCEPT GENERIC_PINDATA";
					read telefone;
				else
					echo "ACCEPT TITLE Informe o numero de seu celular com DDD";
					echo "ACCEPT PROMPT ";
					echo "ACCEPT READ";
					read telefone;
				fi

				log "Telefone informado [${telefone}]";

				if [[ "${telefone}" == ""  || ${#telefone} -lt 11 ]];then
					echo "MESSAGE_BOX 3 0 Celular invalido!";
					acao=2;
				else
					telefone=`echo ${telefone} | sed 's/^0\+//'`;	
					celular="("${telefone:0:2}")"${telefone:2:5}"-"${telefone:7:4};
					echo "ACCEPT TITLE CLIENTE (PINPAD) ";
					echo "ACCEPT PROMPT Confirme o celular! Informar? SIM/NAO";
					echo "ACCEPT PIN_MSG Confirma?       ${celular}  (SIM)- Verde    (NAO)- Vermelho";
					echo "ACCEPT PIN_YESNO";
					read yesno
					if [ "${yesno}" != "NULL" ];then

						log "curl --header 'Content-Type:application/text; Accept: application/text' -H 'store: $store' -H 'pos: $pos' -H 'ticket: $cupom' -H 'idcustomer: $cst_id' -H 'celular: ${telefone}' --connect-timeout ${min} --max-time ${max} -X GET  ${endPoint} -sL";
						OUTPUT=$(curl --header "Content-Type:application/text; Accept: application/text" -H "store: $store" -H "pos: $pos" -H "ticket: $cupom" -H "idcustomer: $cst_id" -H "celular: ${telefone}" --connect-timeout ${min} --max-time ${max} -X GET  ${endPoint} -sL );
						log "CONSULTA -> RETORNO: $OUTPUT";
						if [ ${#OUTPUT} -le 0 ]; then
							echo "ACCEPT TITLE Servico de Consulta Indisponivel";
							echo "ACCEPT PROMPT Tecle ENTRA"
							echo "ACCEPT READ";
							read cmd_rsl;
							flag=1;
							telefone=0;
						else
							cod_return=`echo $OUTPUT | cut -f 1 -d '|'`;
							msg_return=`echo $OUTPUT | cut -f 2 -d '|'`;

							if [[ ${cod_return} == "00" || ${cod_return} == "0" ]];then 
								echo "INTERNAL ANSWER 13 "+55"${telefone}";
								echo "STEP ANSWER 13 0 Celular: "+55"${telefone}";
	
								acao=1;
								flag=1;
								sendToken;

							elif [ ${cod_return} == "-2" ];then
								echo "DISPLAY ${msg_return}";
								echo "MESSAGE_BOX 3 0 ${msg_return}";
								echo "ACCEPT YESNO Tentar outro Celular?";
								read yesno;
								if [ ${yesno} -eq 1 ];then
									acao=1;
								else
									flag=1;
									telefone=0;
								fi
							fi
						fi	
					else
						acao=2;
					fi
				fi
				;;
			"2")
				echo "ACCEPT YESNO Tentar novamente?"
				read yesno

				if [ ${yesno} -eq 1 ];then
					acao=1;
				else
					flag=1;
					telefone=0;
				fi
				;;
		esac
	done;
}
function realizarConsulta(){
        log "Function realizarConsulta.";
        echo "DISPLAY Realizando consulta...";
        endPoint=$server_crm"customer";
	log "curl --header 'Content-Type:application/text; Accept: application/text' -H 'store: $store' -H 'pos: $pos' -H 'ticket: $cupom' -H 'idcustomer: $cst_id' --connect-timeout ${min} --max-time ${max} -X GET  ${endPoint} -sL";
	OUTPUT=$(curl --header "Content-Type:application/text; Accept: application/text" -H "store: $store" -H "pos: $pos" -H "ticket: $cupom" -H "idcustomer: $cst_id" --connect-timeout ${min} --max-time ${max} -X GET  ${endPoint} -sL );
	log "CONSULTA -> RETORNO: $OUTPUT";
	applyCategory=0;   

	echo "INTERNAL ANSWER 491 ${cst_id}";
	echo "STEP ANSWER 491 0 Pre_Cad: ${cst_id}";

	if [ ${#OUTPUT} -le 0 ]; then
		echo "ACCEPT TITLE Servico de Consulta Indisponivel";
		echo "ACCEPT PROMPT Tecle ENTRA"
		echo "ACCEPT READ";
		read cmd_rsl;
	else
		cod_return=`echo $OUTPUT | cut -f 1 -d '|'`;
		msg_return=`echo $OUTPUT | cut -f 2 -d '|'`;
		echo "DISPLAY ${msg_return}";
		[ ${cod_return} == "-1" ] && echo "MESSAGE_BOX 3 0 ${msg_return}";
		if [ ${cod_return} == "00" ];then 
			limparVariaveisGrupo;
			categorias=`echo $OUTPUT | cut -f 4 -d '|'`;
			clienteNome=`echo $OUTPUT | cut -f 5 -d '|'`;
			grupos=`echo $OUTPUT | cut -f 6 -d '|'`;
			echo "CLIENTE_LJREDE=${clienteNome}";
		
			ctGrupo=1;
			IFS=',' read -r -a grup <<< "${grupos}";
			for grupo in "${grup[@]}";do 
				log "Inserido mensagem [${ctGrupo}] ${prefixoGrupo}${ctGrupo}=${grupo}";
				echo "${prefixoGrupo}${ctGrupo}=${grupo}";
				((ctGrupo++));	
			done

			echo "AUTHORIZE OFF";
			echo "COMMAND 111";
			read rsl
			echo "AUTHORIZE ON";

			for categoria in $(eval echo {${categorias}});do
				log "Inserindo a categoria [${categoria}]";
				echo "INSERT_CATEGORY ${categoria}";
				applyCategory=1;
			done
			echo "MESSAGE_BOX 2 13 ${msg_return}";
		elif [ ${cod_return} == "-2" ];then
			echo "MESSAGE_BOX 3 0 ${msg_return}";
			echo "ACCEPT YESNO Realizar pre-cadastro?";
			read yesno;
			if [ ${yesno} -eq 1 ];then
				mobile;	
			fi
		fi	
	        echo "$OUTPUT" > /var/venditor/WRK/CHANGELST.ctl	
	fi
	if [ $applyCategory -eq 1 ]; then
		echo "COMMAND 7 api";
		read rsl
		echo "COMMAND 7 api";
		read rsl
	fi
	
	#	echo "MESSAGE_BOX 3 0 Realizando consulta... aguarde.";
        echo "COMMAND 14";
        read cmd_rsl
}
function identificacaoAbortada(){
        log "Function identificacaoAbortada.";
        echo "DISPLAY Identificacao abortada.";
        echo "MESSAGE_BOX 3 0 Identificacao abortada.";
        echo "COMMAND 14";
        read cmd_rsl
}
function typeConsulta(){
        log "Function typeConsulta.";
        case ${tipo} in
                "menu")
                        typeMenu;
                        break;;
                "bar-pin")
                        typeBarraPinPad;
                        break;;
                *)
                        typePadrao;
                        break;;
        esac
}
function typeMenu(){
        log "Function typeMenu.";
        echo "MENU 1 0 1";
        echo "MENU ITEM 1 Codigo de Barra";
        echo "MENU ITEM 2 CPF Via Teclado";
        echo "MENU ITEM 3 CPF Via Pinpad";
        echo "MENU SELECT 1";

        echo "ACCEPT TITLE Identificacao.";
        echo "ACCEPT PROMPT [ENTRA] Selecione:";
        echo "ACCEPT READ";
        read opcao;
        log "Opcao selecionado [${opcao}]";
        if [ "${opcao}" == "NULL" ];then
                identificacaoAbortada;
        else
                case ${opcao} in
                        "1")
                                identificacaoCodigoBarra;
                                [[ "${codigoBarra}" == "NULL" || "${codigoBarra}" == "" ]] && identificacaoAbortada;
                                break;;
                        "2")
                                identificacaoTeclado;
                                [[ "${cst_id}" == "NULL" || "${cst_id}" == "" ]] && identificacaoAbortada;
                                break;;
                        "3")
                                identificacaoPinpad;
                                [ "${cst_id}" == "NULL" ] && identificacaoAbortada;
#	|| realizarConsulta;
                                break;;
                        "*")
                                echo "DISPLAY Opcao Invalida.";
                                echo "MESSAGE_BOX 3 13 Opcao Invalida.";
                                echo "COMMAND 14";
                                read cmd_rsl
                                break;;
                esac
        fi
}
function typePadrao(){
        log "Function typePatrao.";
        identificacaoCodigoBarra;
        [[ "${codigoBarra}" == "NULL" || "${codigoBarra}" == "" ]] && identificacaoTeclado;
}
function typeBarraPinPad(){
        log "Function typeBarraPinPad.";
        identificacaoCodigoBarra;
        [[ "${codigoBarra}" == "NULL" || "${codigoBarra}" == "" ]] && identificacaoPinpad;
}
function identificacaoCodigoBarra(){
        log "Function identificacaoCodigoBarra.";
        echo "ACCEPT TITLE Leitura do Codigo de Barra:"
        echo "ACCEPT PROMPT Codigo?"
        echo "ACCEPT READ"
        read codigoBarra;
        log "Codigo de Barra informado [${codigoBarra}]";
        if [ "${codigoBarra}" != "NULL" -a  "${codigoBarra}" != "" ];then
	       cst_id=${codigoBarra}; 
	       realizarConsulta;
	fi
}
function identificacaoTeclado(){
        log "Function identificacaoTeclado.";
        echo "ACCEPT TITLE Identificacao via Teclado:"
        echo "ACCEPT PROMPT CPF?"
        echo "ACCEPT READ"
        read cst_id;
        log "CPF informado [${cst_id}]";
        if [ "${cst_id}" == "NULL" -a "${cst_id}" == "" ];then
                identificacaoAbortada;
        else
                validaCpf;
                if [ $valid -eq 0 ]; then
                        echo "ACCEPT YESNO Tentar novamente?";
                        read yesno;
                        log "CPF informado [${yesno}]";
                        [ ${yesno} -eq 1 ] && typeConsulta || identificacaoAbortada;
                else
                        realizarConsulta;
                fi
        fi
}
function coletaCpf() {
        log "Function coletaCpf.";

	echo "AUTHORIZE OFF";

	echo "COMMAND SET 68 OPTION 2 VALUE 1";
	read rsl

	echo "COMMAND SET 68 OPTION 7 VALUE 8";     
	read rsl

	echo "COMMAND SET 68 OPTION 8 VALUE 0";
	read rsl

	echo "COMMAND 68 api";
	read rsl

	echo "AUTHORIZE ON";
	if [ $rsl -eq 1 ]; then
		echo "EVALUATE {RESPOSTA[46]}"
		read cst_id
	fi
}
function identificacaoPinpad(){
        log "Function identificacaoPinpad.";
       	coletaCpf; 
	log "CPF informado [${cst_id}]";
        if [ "${cst_id}" == "NULL" -a "${cst_id}" == "" ];then
                identificacaoAbortada;
        else
                validaCpf;
                if [ $valid -eq 0 ]; then
                        echo "ACCEPT YESNO Tentar novamente?";
                        read yesno;
                        log "CPF informado [${yesno}]";
                       # [ ${yesno} -eq 1 ] && typeConsulta || identificacaoAbortada;
                        [ ${yesno} -eq 1 ] && identificacaoPinpad || identificacaoAbortada;
                else
                        realizarConsulta;
                fi
        fi
}
function limparVariaveisGrupo(){
        log "Function limparVariaveisGrupo.";
	for grupo in {1..6};do
		echo "${prefixoGrupo}${grupo}= ";
	done
}	

for (( ct=1; ct<= $#;ct++));do
        eval "prm=\${$ct}";
        P0=`echo $prm | cut -f 1 -d '='`;
        P1=`echo $prm | cut -d'=' -f2`;
        case ${P0} in
                "--action")
                        action=$P1;
                        ;;
                "--type")
                        tipo=$P1;
                        ;;
        esac
done
evaluate;
case $action in
        "identify")
		ateos;
		#typeConsulta;
		identificacaoPinpad;
                break;
                ;;
        "clear")
                log "Limpando Variaveis -------------------------------------- $VERSION"
		limparVariaveisGrupo;
		echo "CLIENTE_LJREDE= ";
                echo "ENABLERAPPI=0";
                [ -e ../WRK/CHANGELST.ctl ] && rm -f ../WRK/CHANGELST.ctl;
                sair;
                break;
                ;;
        "pre-cadastro")
               PreCadastro; 
		;;
esac
sair;
