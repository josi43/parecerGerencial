*  Begin EG generated code (do not edit this line); 
* 
*  Stored process registered by 
*  Enterprise Guide Stored Process Manager V7.1 
* 
*  ==================================================================== 
*  Stored process name: RESP_EMAIL_SP2 
*  ==================================================================== 
* 
*  Stored process prompt dictionary: 
*  ____________________________________ 
*  MENSAGEM 
*       Type: Text 
*      Label: mensagem 
*       Attr: Hidden 
*  ____________________________________ 
*; 
 
 
*ProcessBody; 
 
%global MENSAGEM; 
 
*  End EG generated code (do not edit this line); 
 
 
%GLOBAL RESP EMAIL ASSUNTO CC CDREGRA anexo ;
%LET MAIL = TRANWRD("&CC",",","' '")  ;
%let _result=streamfragment ;
%let dat = %sysfunc(datetime()) ;

*
=========================================
    IDENTIFICANDO O HOST DE EXECUCAO ;

%MACRO HOSTNAME ;
    %IF "&SYSHOSTNAME" = "dev-sas-srv02" %THEN %DO ;
        DATA HOST ;
            SERVER_HOST = 'http://dev-sas-srv02.desenv.com:7980/SASStoredProcess/do?' ;
            IMAGEM = 'http://10.0.21.121:7980/SASTheme_default/themes/portal banpara - v3/imagens/BANPARA.png' ;
            CSS_FORM = 'http://dev-sas-srv02.desenv.com:7980/SASTheme_default/themes/default/styles/banparacss/simple_form.css' ;
        RUN ;
    %END ;
    %ELSE %IF "&SYSHOSTNAME" = "SAS-SRV" %THEN %DO ;
        DATA HOST ;
            SERVER_HOST = 'http://sas-srv.banpara.com:7980/SASStoredProcess/do?' ;
            IMAGEM = 'http://10.0.100.104:7980/SASTheme_default/themes/portal banpara - v3/imagens/BANPARA.png' ;
            CSS_FORM = 'http://sas-srv.banpara.com:7980/SASTheme_default/themes/default/styles/banparacss/simple_form.css' ;
        RUN ;
    %END ;
    %ELSE %DO ;
    %END ;
%MEND ;
%HOSTNAME ;

PROC SQL NOPRINT ;
    SELECT SERVER_HOST, IMAGEM, CSS_FORM INTO :SERVER_HOST, :IMAGEM, :CSS_FORM FROM HOST ;
QUIT ;

*================================= FIM HOST ;

LIBNAME SNAPLD BASE "/sas/sasdata/BANPARA/PROJETOS/NUCIC/PLD_GERAL/TABELAS/SNA/" ;
LIBNAME SNAPLDV2 BASE "/sas/sasdata/BANPARA/PROJETOS/NUCIC/PLD_GERAL/TABELAS/SNAV2/" ;


proc printto log="/sas/sasdata/BANPARA/PROJETOS/NUCIC/PLD_GERAL/RELATORIOS/SNA/LOGS/NOVO_RESP_EMAIL_GERENTE_%SYSFUNC(SCAN("&_METAUSER",1,"@"))_%sysfunc(datetime(), datetime.).log" new;
run;

/*teste debug */
%put zxcmensagem=&mensagem;
%put email_ger: &email_ger;
%put ae_id: &ae_id;
/*fim teste debug */

PROC SQL; 
   CREATE TABLE WORK.RELATORIO_GERENTE AS  
   SELECT t1.actionableEntityId,  
          CASE WHEN t1.tipo_cliente = 'F' 
            then (substr(t1.CPF_CNPJ_CLIENTE, 1,3)||'.'|| substr(t1.CPF_CNPJ_CLIENTE, 4,3)||'.'|| substr(t1.CPF_CNPJ_CLIENTE, 7,3)||'-'|| substr(t1.CPF_CNPJ_CLIENTE, 10,2))
            else (substr(t1.CPF_CNPJ_CLIENTE, 1,2)||'.'|| substr(t1.CPF_CNPJ_CLIENTE, 3,3)||'.'|| substr(t1.CPF_CNPJ_CLIENTE, 6,3)||'/'|| substr(t1.CPF_CNPJ_CLIENTE, 9,4) ||'-'|| substr(t1.CPF_CNPJ_CLIENTE, 13,2))
            end LABEL="CPF / CNPJ" AS CPF_CNPJ_CLIENTE,  
          t1.NOME_CLIENTE LABEL="CLIENTE" AS NOME_CLIENTE,  
          t1.EMAIL_GERENTE LABEL="EMAIL GERENTE" AS EMAIL_GERENTE,  
          t1.NOME_GERENTE LABEL="NOME DO GERENTE" AS NOME_GERENTE,  
          t1.AGENCIA LABEL="AGÊNCIA" AS AGENCIA,  
          t1.CONTA LABEL="N°  CONTA" AS CONTA,  
          t1.NOME_AGENCIA,  
          t1.ENQUADRAMENTO,  
          t1.VALOR,  
          t1.DATA_MOV LABEL="DATA MOV" AS DATA_MOV,  
          t1.TIPO_CLIENTE 
      FROM SNAPLD.CLIENTE_GERENTE t1 
      WHERE t1.actionableEntityId = "&ae_id";
QUIT; 

DATA EMAIL ;
PUT MAIL $500. ;
MAIL = CAT("'",&MAIL,"'") ;
RUN ;

FILENAME Mailbox EMAIL;

PROC SQL NOPRINT ;
    SELECT MAIL INTO :E_MAIL
    FROM EMAIL ;
QUIT ;

PROC SQL NOPRINT ;
    SELECT DISTINCT CDCLASS INTO :CLASS FROM SNAPLD.TEXTO_PADRAO WHERE CPFCNPJ = substr("&ae_id", 7, 20) ;
QUIT ;

%let CLASS = 10;

%LET dat_prazo = %SYSFUNC(PUTN(%sysfunc(DATEPART("&RESP"dt)), DDMMYY10.)) ;
%LET hora_prazo = %SYSFUNC(PUTN(%sysfunc(TIMEPART("&RESP"dt)), TIME8.)) ;
%LET DIA_SEMANA = %SYSFUNC(WEEKDAY(%SYSFUNC(DATEPART("&RESP"dt)))) ;

PROC SQL NOPRINT ;
    SELECT 
        (CASE
            WHEN(&DIA_SEMANA = 1) THEN "(DOMINGO)."
            WHEN(&DIA_SEMANA = 2) THEN "(SEGUNDA-FEIRA)."
            WHEN(&DIA_SEMANA = 3) THEN "(TERÇA-FEIRA)."
            WHEN(&DIA_SEMANA = 4) THEN "(QUARTA-FEIRA)."
            WHEN(&DIA_SEMANA = 5) THEN "(QUINTA-FEIRA)."
            WHEN(&DIA_SEMANA = 6) THEN "(SEXTA-FEIRA)."
            WHEN(&DIA_SEMANA = 7) THEN "(SÁBADO)."
        END) INTO :DSEMANA
    FROM EMAIL
    ;
QUIT ;

PROC SQL NOPRINT ;
    SELECT DISTINCT 
        actionableEntityId,
        CPF_CNPJ_CLIENTE,
        NOME_CLIENTE,
        CONTA,
        AGENCIA
    INTO 
        :actionableEntityId,
        :cpf_cnpj,
        :NMCLI,
        :CONTA,
        :AGENCIA
    FROM SNAPLD.Cliente_Gerente
    WHERE actionableEntityId = "&ae_id"
    ;
QUIT ;

DATA linkParaGerente ;
var = "'" || '<a href="' || "&SERVER_HOST" || '_program=%2FBANPARA%2FPROJETOS%2FNUCIC%2FPLD_GERAL%2FRELATORIOS%2FSNA%2FREENVIO_EMAIL_SP3&ae_id=' || "&ae_id" || '&NMCLI=' || TRANWRD(translate(strip("&NMCLI"),'_',' '),'&','E') || '&email_ger=' || "&email_ger" || '" title="Novo E-mail"> Enviar Novo E-mail</a>' || "'" ;
RUN ;

PROC SQL NOPRINT ;
    SELECT var into :link_resp from linkParaGerente ;
QUIT ;

%MACRO listaGerente ;
%PUT NMCLI: &NMCLI;
%STPBEGIN ;  
PROC TABULATE 
DATA=WORK.RELATORIO_GERENTE(FIRSTOBS=1 ) ; 
    VAR VALOR; 
    CLASS CPF_CNPJ_CLIENTE /    ORDER=UNFORMATTED MISSING; 
    CLASS NOME_CLIENTE /    ORDER=UNFORMATTED MISSING; 
    CLASS AGENCIA / ORDER=UNFORMATTED MISSING; 
    CLASS CONTA /   ORDER=UNFORMATTED MISSING; 
    CLASS NOME_GERENTE /    ORDER=UNFORMATTED MISSING; 
    CLASS ENQUADRAMENTO /   ORDER=UNFORMATTED MISSING; 
    CLASS DATA_MOV /    ORDER=UNFORMATTED MISSING; 
    TABLE /* Page Dimension */ 
NOME_GERENTE, 
/* Row Dimension */ 
CPF_CNPJ_CLIENTE* 
  NOME_CLIENTE* 
    AGENCIA* 
      CONTA* 
        ENQUADRAMENTO* 
          DATA_MOV* 
            Sum={LABEL="" STYLE={NOBREAKSPACE=ON}}*F=COMMAX12.2*{STYLE={NOBREAKSPACE=ON}}, 
/* Column Dimension */ 
VALOR       ; 
    ; 
RUN;  
%STPEND ;
%MEND ;

/*Raul, Inicio*/
%MACRO EMAIL;
%put entrou no email;
PROC SQL ;
    CREATE TABLE CONSULTA2 AS
    SELECT CPF_CNPJ, NOME_CLIENTE, AGENCIA, STATUS_CLIENTE, TEXTO_RESP, EMAIL_ORIGEM, EMAIL_DESTINO,
       DATEPART(&dat) FORMAT DDMMYY10. AS ENVIO, 
       INPUT(DATA_RETORNO_MAX, YYMMDD10.) FORMAT DDMMYY10. AS RETORNO,
    CASE 
    WHEN DATEPART(&dat) > INPUT(DATA_RETORNO_MAX, YYMMDD10.) THEN 1 ELSE 0 END AS FLAG_FORA_PRAZO 
    FROM SNAPLD.HIST_EMAIL
    WHERE DATEPART(&dat) > INPUT(DATA_RETORNO_MAX, YYMMDD10.) AND NUM_SP IN ('EMAIL_1', 'EMAIL_3') 
    AND actionableEntityId= "&actionableEntityId"
    ORDER BY actionableEntityId DESC;
quit;
PROC SQL ;
  SELECT COUNT(*)
  INTO :entity_id_count
  FROM consulta2
  WHERE  CPF_CNPJ= "&CPF_CNPJ";
QUIT;
    /*%let dat = %sysfunc(datetime()) ;*/
    %LET USER = %SYSFUNC(SCAN("&_METAUSER",1,"@"));
    %if &entity_id_count = 0 %then %do;
    PROC SQL NOPRINT ;
        SELECT USUARIO, EMAIL_ORIGEM INTO, DATA_RETORNO_MAX :USER_ANT, :EMAIL_TO, RETORNO_MAX
        FROM SNAPLD.HIST_EMAIL
        WHERE COMPRESS(NUM_SP, " ") = "EMAIL_1" AND actionableEntityId = "&actionableEntityId" ;
    QUIT ;

    PROC SQL NOPRINT ;
        SELECT INDICADOR_PAINEL INTO :PAINEL FROM SNAPLDV2.TELAINICIAL_NEW
        WHERE actionableEntityId = "&actionableEntityId" ;
    QUIT ;

    PROC SQL ;
        INSERT INTO SNAPLD.HIST_EMAIL
            (
                actionableEntityId, CPF_CNPJ, NOME_CLIENTE, EMAIL_ORIGEM, EMAIL_DESTINO,
                DT_ENVIO, DATA_RETORNO_MAX, NUM_SP, USUARIO, TEXTO_RESP, STATUS_CLIENTE, AGENCIA, visita
            )
        VALUES("&actionableEntityId", "&cpf_cnpj", "&NMCLI", "&email_ger",
            "&EMAIL_TO", &dat, ".", "EMAIL_2", "&USER", "&mensagem", "&sel_ger", &AGENCIA, "&visita") ;
    QUIT ;
    
    
        
        PROC SQL ;
            INSERT INTO SNAPLD.ANALISE_PLD
            (
                DTH, USUARIO, actionableEntityId, CPF_CNPJ, STATUS, COMENTARIO,
                PAINEL_ORIGEM, PAINEL
            )
            VALUES
            (
                &dat, "&USER_ANT", "&actionableEntityId", "&CPF_CNPJ", "EM INVESTIGACAO", "",
                "&PAINEL", "&PAINEL"
            ) ;
        QUIT ;

        PROC SQL ;
            UPDATE SNAPLD.TELAINICIAL
            SET STATUS = "EM INVESTIGACAO", USUARIO = "&USER_ANT"
            WHERE actionableEntityId = "&actionableEntityId" ;
        QUIT ;

        PROC SQL ;
            INSERT INTO SNAPLDV2.ANALISE_PLD
            (
                DTH, USUARIO, actionableEntityId, CPF_CNPJ, STATUS, COMENTARIO,
                PAINEL_ORIGEM, PAINEL
            )
            VALUES
            (
                &dat, "&USER_ANT", "&actionableEntityId", "&CPF_CNPJ", "EM INVESTIGACAO", "",
                "&PAINEL", "&PAINEL"
            ) ;
        QUIT ;

        PROC SQL ;
            UPDATE SNAPLDV2.TELAINICIAL_NEW
            SET STATUS = "EM INVESTIGACAO", USUARIO = "&USER_ANT"
            WHERE actionableEntityId = "&actionableEntityId" ;
        QUIT ;
    %END;
%MEND;
 /*Fim*/

 %MACRO DADOS ;
     /*Variavel _webin deve ser declarada/preenchida por um input form*/
     %if %symexist(submit) %then %do ;
    
     %EMAIL;
     PROC SQL NOPRINT ;
         SELECT EMAIL_ORIGEM INTO :EMAIL_TO 
         FROM SNAPLD.HIST_EMAIL
         WHERE COMPRESS(NUM_SP, " ") = "EMAIL_1" AND actionableEntityId = "&actionableEntityId" ;
     QUIT ;
             /* Tratamento de anexo*/
             %if %symexist(_webin_file_count) %then 
             %do ;
                 %put web exist ok;
                 %put _webin_file_count: &_webin_file_count;    
                 /*Tratamento de apenas 1 arquivo*/
                 %if &_webin_file_count = 1 %then 
                 %do;
                         /*local do arquivo no diretorio de work(temp)*/
                     %let file_upload=%sysfunc(pathname(&_webin_fileref));
                     %let str_path_conversa = /sas/sasdata/BANPARA/PROJETOS/NUCIC/PLD_GERAL/ARQUIVOS_EXTERNOS/CONVERSAS_GERENTE_SNA/&ae_id/'&email_ger';
                         /*path permanente do arquivo*/
                     %let str_dir_gerente = /sas/sasdata/BANPARA/PROJETOS/NUCIC/PLD_GERAL/ARQUIVOS_EXTERNOS/CONVERSAS_GERENTE_SNA/&ae_id/'&email_ger'/'&_WEBIN_FILENAME';
                     %let atch_str_dir_gerente = /sas/sasdata/BANPARA/PROJETOS/NUCIC/PLD_GERAL/ARQUIVOS_EXTERNOS/CONVERSAS_GERENTE_SNA/&ae_id/&email_ger/&_WEBIN_FILENAME;
                     
                     systask command "mkdir -p /sas/sasdata/BANPARA/PROJETOS/NUCIC/PLD_GERAL/ARQUIVOS_EXTERNOS/CONVERSAS_GERENTE_SNA/&ae_id/'&email_ger'" wait status=movefl;
                     systask command "mv &file_upload &str_dir_gerente" wait status=movefl;
                     
                      %PUT atch_str_dir_gerente: &atch_str_dir_gerente;                     
                     /*Novo diretorio
                     %let str_dir_gerente_pj = /sas/sasdata/BANPARA/PROJETOS/NUCIC/PLD_GERAL/ARQUIVOS_EXTERNOS/CONVERSAS_GERENTE_PJ/&ae_id/&_WEBIN_FILENAME;
 */
                 %end;/*1 arquivo*/
                 %else 
                 %do;
                     %let str_path_conversa = /sas/sasdata/BANPARA/PROJETOS/NUCIC/PLD_GERAL/ARQUIVOS_EXTERNOS/CONVERSAS_GERENTE_SNA/&ae_id/;
                     /*loop mais de 1 arquivo*/
                     %do i=1 %to &_webin_file_count ;
                         %let file_upload&i = %sysfunc(pathname(&&_webin_fileref&i));
                         %let str_dir_gerente&i = /sas/sasdata/BANPARA/PROJETOS/NUCIC/PLD_GERAL/ARQUIVOS_EXTERNOS/CONVERSAS_GERENTE_SNA/&ae_id/'&email_ger'/'&&_WEBIN_FILENAME&i';
                         %let atch_str_dir_gerente&i = /sas/sasdata/BANPARA/PROJETOS/NUCIC/PLD_GERAL/ARQUIVOS_EXTERNOS/CONVERSAS_GERENTE_SNA/&ae_id/&email_ger/&&_WEBIN_FILENAME&i;
                         %put loop: &i;
                         /* Criar path caso não exista, caso não exista, sem ação (parametro -p)*/
                         systask command "mkdir -p /sas/sasdata/BANPARA/PROJETOS/NUCIC/PLD_GERAL/ARQUIVOS_EXTERNOS/CONVERSAS_GERENTE_SNA/&ae_id/'&email_ger'" wait status=movefl;
                         systask command "mv &&file_upload&i &&str_dir_gerente&i" wait status=movefl;
 
                         %put file_upload&i : &&file_upload&i ;
                         %put str_dir_gerente&i : &&str_dir_gerente&i;
                         /*macro adiciona todos os anexos com o loop*/
                     /* ATTACH=("&&str_dir_gerente&i" content_type="&&_WEBIN_CONTENT_TYPE&i")*/
                         
                     %end;/*Fim loop mais de 1 arquivo*/
                 %end;/*Fim else 1 arquivo*/
             %put " debug server path: &str_path_conversa <br>";
             %put " debug actionable: &ae_id <br>";
             %end;/*Fim Tratamento de anexo*/
             /*envio de email*/
             /* tratar se fora do prazo ou não */
             PROC SQL ;
                CREATE TABLE CONSULTA2 AS
                SELECT CPF_CNPJ, NOME_CLIENTE, AGENCIA, STATUS_CLIENTE, TEXTO_RESP, EMAIL_ORIGEM, EMAIL_DESTINO,
                DATEPART(&dat) FORMAT DDMMYY10. AS ENVIO, 
                INPUT(DATA_RETORNO_MAX, YYMMDD10.) FORMAT DDMMYY10. AS RETORNO,
                CASE 
                WHEN DATEPART(&dat) > INPUT(DATA_RETORNO_MAX, YYMMDD10.) THEN 1 ELSE 0 END AS FLAG_FORA_PRAZO 
                INTO :CPF_CNPJ, :NMCLI, :AG, :STATUS, :TEXT_RESP, :MAIL_ORI, :MAIL_DEST, :ENVIO, :RETORNO, :FLAG_PRAZO
                FROM SNAPLD.HIST_EMAIL
                WHERE DATEPART(&dat) > INPUT(DATA_RETORNO_MAX, YYMMDD10.) AND NUM_SP IN ('EMAIL_1', 'EMAIL_3') 
                AND actionableEntityId= "&actionableEntityId"
                ORDER BY actionableEntityId DESC;
            quit;
            PROC SQL ;
            SELECT COUNT(*)
            INTO :entity_id_count
            FROM consulta2
            WHERE  CPF_CNPJ= "&CPF_CNPJ";
            QUIT;
        %if &entity_id_count = 0 %then %do;
            
            options emailsys=smtp;
            options emailauthprotocol=none;
            options EMAILHOST = MAILSRV.banpara.com;
             DATA _NULL_ ;
             FILE MailBox LRECL=700 type='text/html'
          
            TO=("&EMAIL_TO")
            CC=("pld_anticorrupcao@banparanet.com.br")
            FROM=("&email_ger")
            SUBJECT="RE: QUESTIONAMENTO RESPONDIDO - &NMCLI - &CPF_CNPJ"
 
                 /* Tratamento de anexo*/
             %if %symexist(_webin_file_count) %then 
             %do ;
                     
                 /*Tratamento de apenas 1 arquivo*/
                 %if &_webin_file_count = 1 %then 
                 %do;
                     ATTACH=("&atch_str_dir_gerente" content_type="&_WEBIN_CONTENT_TYPE") 
                 %end;/*1 arquivo*/
                 %else 
                 %do;
                     /*loop mais de 1 arquivo*/
                     %do i=1 %to &_webin_file_count ;
                         
                     ATTACH=("&&atch_str_dir_gerente&i" content_type="&&_WEBIN_CONTENT_TYPE&i")
                         
                     %end;/*Fim loop mais de 1 arquivo*/
                 %end;/*Fim else 1 arquivo*/
             %end;/*Fim Tratamento de anexo*/
             
             ; /*<< FIM PARAMETROS DE EMAIL, INICIO CORPO DO EMAIL*/
 
             %IF &sel_ger = NAO_SUSPEITO %THEN %DO;
                 PUT "Cliente <strong>não</strong> considerado suspeito." ;
                 PUT "<br><br>";
             %END;
             %IF &sel_ger = SUSPEITO %THEN %DO;
                 PUT "<strong>Atenção!</strong> cliente considerado suspeito." ;
                 PUT "<br><br>";
             %END;
             PUT "&mensagem" ;
             PUT "<br><br><br>";
             PUT "Caso ainda tenha requisições a fazer, clique no link a seguir:";
             PUT &link_resp;
             
             /*PUT '!EM_ATTACH!' ATTACH;*/
         RUN ;
 
         /* Fechar janela após enviar */
         data _null_ ;
             file _webout ;
             put '<h1>E-mail enviado com sucesso. Obrigado.</h1>';
         /* put "<script> window.alert('E-mail enviado com sucesso!');";
             put    'window.open("", "_self");';
               put 'window.close();';
             put " </script>";*/
         run ;
         /* Fechar janela após enviar ?*/
 
         *** ENVIO DE E-MAIL PARA O GERENTE ;
         DATA _NULL_ ;
             FILE MailBox LRECL=700 type='text/html'
           
            TO=("&EMAIL_TO")
            CC=("&email_ger")
            FROM=("&email_ger")
             SUBJECT="RE: QUESTIONAMENTO RESPONDIDO - &NMCLI - &CPF_CNPJ"
 
                 /* Tratamento de anexo*/
             %if %symexist(_webin_file_count) %then 
             %do ;
                     
                 /*Tratamento de apenas 1 arquivo*/
                 %if &_webin_file_count = 1 %then 
                 %do;
                     ATTACH=("&atch_str_dir_gerente" content_type="&_WEBIN_CONTENT_TYPE") 
                 %end;/*1 arquivo*/
                 %else 
                 %do;
                     /*loop mais de 1 arquivo*/
                     %do i=1 %to &_webin_file_count ;
                         
                     ATTACH=("&&atch_str_dir_gerente&i" content_type="&&_WEBIN_CONTENT_TYPE&i")
                         
                     %end;/*Fim loop mais de 1 arquivo*/
                 %end;/*Fim else 1 arquivo*/
             %end;/*Fim Tratamento de anexo*/
             
             ; /*<< FIM PARAMETROS DE EMAIL, INICIO CORPO DO EMAIL*/
 
             %IF &sel_ger = NAO_SUSPEITO %THEN %DO;
                 PUT "Cliente <strong>não</strong> considerado suspeito." ;
                 PUT "<br><br>";
             %END;
             %IF &sel_ger = SUSPEITO %THEN %DO;
                 PUT "<strong>Atenção!</strong> cliente considerado suspeito." ;
                 PUT "<br><br>";
             %END;
             PUT "&mensagem" ;
             PUT "<br><br><br>";
         RUN ;
        %end;
        %else %do;/*tratar fora do prazo*/
            /* Fechar janela após enviar */
            data _null_ ;
                file _webout ;
                put '<h1>Resposta bloqueada pois está fora do prazo máximo. Favor entrar em contato com a área de PLD.</h1>';
            /*  put "<script> window.alert('E-mail enviado com sucesso!');";
                put 'window.open("", "_self");';
                put 'window.close();';
                put " </script>";*/
            run ;
                %end;
     %END ;
     %else %do;
    PROC SQL NOPRINT ;
        SELECT SERVER_HOST, IMAGEM, CSS_FORM INTO :SERVER_HOST, :IMAGEM, :CSS_FORM FROM HOST ;
    QUIT ;

    proc stream outfile=_webout;
    BEGIN

    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <title>Relatório de Visita</title>
        <link rel="icon" type="image/x-icon" href="./assets/favicon.png">
        <style>
            body {
                font-family: Arial, sans-serif;
                margin-right: 20rem;
                margin-left: 20rem;
                padding: 20px;
            }
            table {
                width: 100%;
                border-collapse: collapse;
                margin-bottom: 20px;
            }
            th, td {
                padding: 8px;
                border: 1px solid #0a0a0a;
                text-align: left;
            }
     
            h1 {
                font-size: 24px;
            }
            h2 {
                font-size: 20px;
            }
            h3 {
                font-size: 18px;
            }
            h4 {
                font-size: 16px;
                font-weight: bold;
                margin-top: 10px;
            }
            p {
                margin: 5px 0;
            }
            ul {
                list-style-type: disc;
                margin-left: 20px;
            }
            select, input, option {
                width: 70%;
                padding: 10px;
                margin: 10px;
                border: 0px solid #fcfcfc;
                background-color: #ffffff;
                border-radius: 10px;
                font-weight: bold;
                font-size: medium;
            }
            select {
                appearance: none; 
                padding: 10px;
                background-color: #f0f0f0;
                border: 1px solid #ccc;
                border-radius: 10px;
            }
            select:hover {
              
                background-color: #f0c0c0;
            }
            option {
              
                padding: 5px;
            }
            option:hover {
           
                background-color: #ffbfbf;
            }
        </style>
    </head>
    <body>
        <table>
            <img src="./assets/logo.png"/>
            <tr>
                <th colspan="2">Núcleo de Controle Interno e Compliance - NUCIC</th>
            </tr>
            <tr>
                <th colspan="2">Subnúcleo de Prevenção à Lavagem de Dinheiro e Anticorrupção</th>
            </tr>
            <tr>
                <th colspan="2">POLÍTICA "CONHEÇA SEU CLIENTE" - MNP DE PREVENÇÃO AO CRIME DE LAVAGEM DE DINHEIRO</th>
            </tr>
        </table>
        <table>
    
        <th><h3>Leis Aplicáveis:</h3></th>
        <td>
        <ul>
            <li>Lei 9.613/98</li>
            <li>Lei 12.683/12</li>
            <li>Circular BACEN 3.461</li>
        </ul>
        </td>
        </table>
        <table>
            <tr>
                <th>1. UNIDADE:</th>
            </tr>
            <tr>
                <th>1.1 IDENTIFICAÇÃO DO CLIENTE</th>
            </tr>
            <tr>
                <td><b>Nome:</b><p>&NMCLI</p></td>
            </tr>
            <tr>
                <td><b>CPF/CNPJ:</b> <p>&cpf_cnpj</p></td>
                
            </tr>
            <tr>
                <td><b>Data de Nascimento/Início da Atividade:</b> <input type="text" id="cliente_data_nascimento"></td>
              
            </tr>
            <tr>
                <td><b>Cliente desde:</b> <input type="date" id="cliente_desde"></td>
               
            </tr>
            <tr>
                <td><b>Agência: </b><p>&AGENCIA</p></td>
              
            </tr>
            <tr>
                <td><b>Nº da Conta:</b>
                    <p>&CONTA</p><br>
                <select name="visita" id="cliente_conta">
                    <option>Selecione:</option>
                    <option value="conta_corrente">Conta corrente</option>
                    <option value="poupanca">Poupança</option>
                </select></td></td>
               
            </tr>
            <tr>
                <td><b>Fone:</b> <input type="number" id="cliente_fone"></td>
            </tr>
            <tr>
                <td><b>Endereço:</b> <input type="text" id="cliente_endereco"></td>
            </tr>
            <tr>
                <td><b>PERGUNTA: A localização do Cliente/Atividade é consistente com as declarações fornecidas?</b>  <br> 
                    <select name="visita" id="pergunta_localizacao">
                    <option>Selecione:</option>
                    <option value="SIM">Sim</option>
                    <option value="NÃO">Não</option>
                    <option value="NSA">Não se Aplica</option>
                </select></td>
            </tr>
            <tr>
                <td><b>Justifique (caso negativo):</b> <input type="text" id="justificativa_localizacao"></td>
            </tr>
        </table>
    
        <table>
            <tr>
                <th>2. SITUAÇÃO CADASTRAL:</th>
               
            </tr>
            <tr>
                <td><b>Data da última atualização:</b><br><br>
                    <input type="date" id="data_atualizacao"><br>
                    <select name="status_atualizacao" id="status_atualizacao">
                        <option>Selecione:</option>
                        <option value="atualizado">Atualizado</option>
                        <option value="vencido">Vencido</option>
                    </select>
                </td>
            </tr>
        </table>
        <table>
            <tr>
            <th colspan="2">3. Identificação do procurador e referências</th>
            </tr>
            <tr>
            <td><b>3.1 Conta movimentada por procuração?</b><br>
                <select name="procuração" id="movimentacao_procuracao">
                    <option>Selecione:</option>
                    <option value="sim">Sim</option>
                    <option value="nao">Não</option>
                </select>         
            </td>
            <td>
                <b>Data vencimento procuração:</b>
                <P>&RETORNO_MAX</P>
            </td>
        </tr>
        <tr>
            <td>
                <b>Nome:</b>
                <p>&NMCLI</p>
            </td>
            <td>
                <b>CPF/CNPJ: </b>
                <P>&CPF_CNPJ</P>
            </td>
        </tr>
        <td colspan="2">
            <b>Endereço:</b>
            <input type="text">
        </td>
        </table>
        <table>
            <tr>
                <th colspan="3">
                    <b> 4. Informações Econônico-Financeias</b>
                </th>
            </tr>
                <td  colspan="3"    >
                    <b> Ocupação profissional/ramo de atividade:</b>
                    <input type="text">
                </td>
            <tr >
                <td >
                    <b> Renda mensal/faturamento mensal:</b>
                    <input type="text">
                </td>
                <td colspan="2">
                    <b> Movimentação Financeira Média Mensal:</b>
                    <input type="text">
                </td>
            </tr>
            <td colspan="3">
                <b>Detalhamento da origem/destinação dos recursos movimentados: </b>
                <input type="text">
            </td>
            <tr>
            <td colspan="2">
                <b>PERGUNTA:</b> A Movimentação Financeira é compatível com a Ocupação 
                Profissional/Atividade e a Capacidade Econômico-Financeira/Faturamento
                 presumido do cliente? 
            </td>
            <td>
                <select>
                <option>Selecione:</option>
                <option>Sim</option>
                <option>Não</option>
                </select>
            </td>
            </tr>
            <tr>
                <td colspan="3">
                    Justifique (caso negativo):
                    <input type="text">
                </td>
            </tr>
            <tr>
                <td>
                    <b>Veículos</b><br>
                    <select>
                        <option>Selecione:</option>
                        <option>Sim</option>
                        <option>Não</option>
                    </select>
                </td>
                <td>
                    <b>Valor:</b>
                    <input type="number">
                </td>
                <td><b>Detalhar: </b> <input type="text"></td>
            </tr>
            <tr>
                <td>
                    <b>Bens Imóveis</b><br>
                    <select>
                        <option>Selecione:</option>
                        <option>Sim</option>
                        <option>Não</option>
                    </select>
                </td>
                <td>
                    <b>Valor:</b>
                    <input type="number">
                </td>
                <td><b>Detalhar: </b> <input type="text"></td>
            </tr>
            <tr>
                <td>
                    <b>Part. Societária</b><br>
                    <select>
                        <option>Selecione:</option>
                        <option>Sim</option>
                        <option>Não</option>
                    </select>
                </td>
                <td>
                    <b>Valor:</b>
                    <input type="number">
                </td>
                <td><b>Detalhar: </b> <input type="text"></td>
            </tr>
            <tr>
                <td>
                    <b>Outros bens</b><br>
                    <select>
                        <option>Selecione:</option>
                        <option>Sim</option>
                        <option>Não</option>
                    </select>
                </td>
                <td>
                    <b>Valor:</b>
                    <input type="number">
                </td>
                <td><b>Detalhar: </b> <input type="text"></td>
            </tr>
            <tr>
                <td colspan="2">
                    <b>PERGUNTA:</b> Os Bens patrimoniais são compatíveis com a Ocupação Profissional/Atividade e a 
                    Capacidade Econômico-Financeira/Faturamento presumido do cliente?  
                </td>
                <td>
                    <select>
                    <option>Selecione:</option>
                    <option>Sim</option>
                    <option>Não</option>
                    </select>
                </td>
                </tr>
                <tr>
                    <td colspan="3">
                        Justifique (caso negativo):
                        <input type="text">
                    </td>
                </tr>
        </table>
        <table>
            <tr>
                <th colspan="3">5. PARECER DO GERENTE:</th>
            </tr>
            <tr>
                <td><b>MOVIMENTAÇÃO NÃO SUSPEITA </b>
                    <select name="movimentacao" id="movimentacao_nao_suspeita">
                        <option>Selecione:</option>
                        <option value="movimentacao_n_suspeita">Movimentação não suspeita</option>
                        <option value="movimentacao_suspeita">Movimentação suspeita</option>
                    </select>
                </td>
            
                <td><b>DATA DA VISITA: </b><input type="date" id="cliente_desde">
                <td><b>ASSINATURA E CARIMBO DO RESPONSÁVEL PELA VISITA: </b>
                    <input type="text" id="assinatura_responsavel"></td>
            </tr>
        </table>
        <p>Este Relatório deverá ser obrigatoriamente arquivado e deverá ficar à disposição das Auditorias Interna, Externa e BACEN. As informações registradas neste Relatório são de caráter sigiloso e de exclusiva responsabilidade da Administração da Unidade.</p>
    </body>
    </html>
    

;;;;
run ;



    %end;
    
%MEND ;

%DADOS ;



%STPBEGIN;
/* debug webin 
proc sql ;
select * from dictionary.macros
where name like '_WEBIN_%' ;
quit ;
/**/
%STPEND; 
 
*  Begin EG generated code (do not edit this line); 
;*';*";*/;quit; 
 
*  End EG generated code (do not edit this line);