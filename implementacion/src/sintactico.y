%{

#include <cstdlib>
#include <cstdio>
#include <string>

using namespace std;

int yylex();
void yyerror(const char * mensaje);

int num_linea = 1;

#include "estructuras_datos.h"

#define MAX_TS 500

unsigned long int TOPE = 0;
unsigned long int TOPE_PARAMF = 0;
bool subprog = false;
dtipo tipoTmp;


entradaTS TS[MAX_TS];

// necesitamos pila auxiliar para los parametros, porque si no
// los introduce antes de la funcion, por la forma de expandir reglas de bison
entradaTS TS_paramf[MAX_TS];

typedef struct {
	int atrib;
	string lexema;
	dtipo tipo;
} atributos;

#define YYSTYPE atributos

// falta funciones:
// insertar
// modificar
// consultar

void TS_InsertaIDENT(atributos atrib);

void TS_InsertaMARCA();

void TS_VaciarENTRADAS();

void TS_InsertaSUBPROG(atributos atrib);

void TS_InsertaPARAMF(atributos atrib);

int incrementaTOPE();

dtipo encontrarEntrada(string nombre, bool quiero_que_este);

bool esFuncion(string nombre);

void comprobarEsVarOParamametroFormal(atributos atrib);

void comprobarEsTipo(dtipo tipo, atributos atrib);

string tipoAstring(dtipo tipo);


%}
%error-verbose

%token CONSTANTE_BASICA
%token CORCHETE_ABRE
%token CORCHETE_CIERRA
%token COMA
%token OP_EXC_BIN
%token MENOS
%token OP_EXC_UN
%token ARROBA
%token MASMAS
%token ID
%token PYC
%token PARENTESIS_ABRE
%token PARENTESIS_CIERRA
%token DOLAR
%token AVANZAR
%token RETROCEDER
%token ENTRADA
%token SALIDA
%token MIENTRAS
%token REPETIR
%token DEVUELVE
%token SI
%token SINO
%token ASIGNACION
%token LISTADE
%token LLAVE_ABRE
%token LLAVE_CIERRA
%token TIPO_BASICO
%token PRINCIPAL
%token CADENA
%token VAR

%left OP_EXC_BIN
%right OP_EXC_UN
%left MENOS
%left MASMAS
%left ARROBA


%left CORCHETE_ABRE
%left CORCHETE_CIERRA


%start programa

%%

programa					: PRINCIPAL bloque ;


bloque						: LLAVE_ABRE  { TS_InsertaMARCA(); }
								  variables
								  declar_subprogramas
								  sentencias
								  LLAVE_CIERRA { TS_VaciarENTRADAS(); };



variables					: declar_variables
				 				| ;

declar_variables			: declar_variables cuerpo_declar_var
						 		| cuerpo_declar_var ;

cuerpo_declar_var			: VAR tipo ident_variables PYC ;

ident_variables             : ident_variables COMA ID { TS_InsertaIDENT($3); }
                                | ident_variables COMA ID ASIGNACION expresion { TS_InsertaIDENT($3); }
                                | ID { TS_InsertaIDENT($1); }
                                | ID ASIGNACION expresion {  TS_InsertaIDENT($1); comprobarEsTipo($1.tipo, $3); }
										  | error ;

expresion                   : PARENTESIS_ABRE expresion PARENTESIS_CIERRA {$$.tipo = $2.tipo;}
                                | OP_EXC_UN expresion
                                | expresion OP_EXC_BIN expresion
                                | expresion MENOS expresion
                                | expresion MASMAS expresion ARROBA expresion
                                | MENOS expresion
                                | llamada_subprograma
                                | ID							{dtipo t = encontrarEntrada($1.lexema, true); $$.tipo = $1.tipo;}
                                | constante
										  | error ;

constante                   : CONSTANTE_BASICA {tipoTmp = $1.tipo;}
                                | CORCHETE_ABRE contenido_lista CORCHETE_CIERRA ;

contenido_lista             : contenido_lista_preced CONSTANTE_BASICA
                                | CONSTANTE_BASICA
                                | ;

contenido_lista_preced      : contenido_lista_preced CONSTANTE_BASICA COMA
                                | CONSTANTE_BASICA COMA ;


llamada_subprograma         : ID PARENTESIS_ABRE lista_variables_constantes PARENTESIS_CIERRA;



declar_subprogramas         : declar_subprogramas declar_subp
                                | ;

declar_subp                 : cabecera_subp {subprog = true;}
									 	bloque  {subprog = false;} ;

cabecera_subp               : tipo ID PARENTESIS_ABRE parametros PARENTESIS_CIERRA { TS_InsertaSUBPROG($2);  }
									 | error;

tipo                        : TIPO_BASICO {tipoTmp = $1.tipo; }
                                | LISTADE TIPO_BASICO
										  | error ;

parametros                  : parametro
                                | parametro_preced parametro
                                | ;

parametro                   : tipo ID { TS_InsertaPARAMF($2); };

parametro_preced            : parametro_preced parametro COMA
                                | parametro COMA;

sentencias                  : sentencias sentencia
                                | ;

sentencia                   : bloque
                                | ID ASIGNACION expresion PYC { comprobarEsTipo(encontrarEntrada($1.lexema, true), $3);}
                                | SI PARENTESIS_ABRE expresion PARENTESIS_CIERRA sentencia {comprobarEsTipo(booleano, $3); }
                                | SI PARENTESIS_ABRE expresion PARENTESIS_CIERRA sentencia SINO sentencia {comprobarEsTipo(booleano, $3); }
                                | MIENTRAS PARENTESIS_ABRE expresion PARENTESIS_CIERRA sentencia {comprobarEsTipo(booleano, $3); }
                                | REPETIR sentencia MIENTRAS PARENTESIS_ABRE expresion PARENTESIS_CIERRA PYC {comprobarEsTipo(booleano, $5); }
                                | DEVUELVE expresion PYC
                                | ID AVANZAR PYC
                                | ID RETROCEDER PYC
                                | DOLAR ID PYC
                                | ENTRADA lista_variables PYC
                                | SALIDA lista_expresiones_o_cadena PYC ;

lista_variables             : lista_variables COMA ID {comprobarEsVarOParamametroFormal($3);}
                                | ID {comprobarEsVarOParamametroFormal($1);} ;


lista_variables_constantes  : lista_variables_constantes COMA ID {comprobarEsVarOParamametroFormal($3);}
                                | lista_variables_constantes COMA constante
                                | constante
                                | ID {comprobarEsVarOParamametroFormal($1);} ;

lista_expresiones_o_cadena  : lista_expresiones_o_cadena COMA CADENA
									 	  | lista_expresiones_o_cadena COMA expresion
                                | CADENA
                                | expresion ;

%%


#include "lex.yy.c"

#include "estructuras_datos.h"

void yyerror(const char *msg)
{
    fprintf(stderr,"[Linea %d]: %s\n", num_linea, msg) ;
}


// Funcion para insertar un atributo en la tabla de simbolos
void TS_InsertaIDENT(atributos atributo){

	//printf("Identificador %s\n\n", atributo.lexema.c_str());

	// preparamos la nueva entrada
	entradaTS nueva_entrada;

	// es de tipo variable
	nueva_entrada.entrada = variable;

	// y tiene el nombre del atributo dado
	nueva_entrada.nombre = atributo.lexema;

	// ponemos parametros a 0 porque no este a basura
	nueva_entrada.parametros = 0;

	// el tipo es el leido en la variable temporal en yacc
	nueva_entrada.tipoDato = tipoTmp;

	// pasamos a buscar si se ha declarado otro con el mismo nombre dentro de la
	// misma marca
	int pos_id_buscado = TOPE - 1;
	bool encontrado = false;

	while ( pos_id_buscado >= 0 && TS[pos_id_buscado].entrada != marca && !encontrado) {

		if ( atributo.lexema == TS[pos_id_buscado].nombre ) {
			encontrado = true;
		} else {
			pos_id_buscado--;
		}
	}

	// si no se ha declarado, lo añadimos
	if ( !encontrado ) {

		TS[TOPE] = nueva_entrada;

		incrementaTOPE();

	} else {
		// si se ha declarado antes, mostramos un error
		// como los parametros de funciones son añadidos tras la marca de bloque, se tendrá en cuenta sus redeclaraciones
		printf("Error semantico: Redeclaración de '%s' en la linea %d\n", atributo.lexema.c_str(), num_linea);
	}


}

// funcion para insertar el comienzo de bloque
void TS_InsertaMARCA(){

	// preparamos la nueva entrada, que sera una marca
	entradaTS nueva_entrada;

	nueva_entrada.entrada = marca;

	// metemos cadena vacia siempre al meter algo, por si encontramos sin querer
	// por el tema de basura
	nueva_entrada.nombre = "";
	nueva_entrada.tipoDato = no_asignado;

	// la introducimos en la pila, y la incrementamos el tope
	TS[TOPE] = nueva_entrada;

	incrementaTOPE();

	// si estamos en un subprograma, debemos añadir los parametros formales
	// como variables. Tambien vaciamos la pila de parametros ya que es el
	// ultimo paso en el que la usamos
	if ( subprog ){

		// mientras queden elementos en la pila
		while (TOPE_PARAMF > 0){
			// simplemente vamos volcandolos, decrementando un contador e
			// incrementando otro
			TS[TOPE] = TS_paramf[TOPE_PARAMF - 1];

			TOPE_PARAMF--;
			incrementaTOPE();
		}
	}

}

// vaciar las entradas de la pila hasta la ultima marca
void TS_VaciarENTRADAS(){

	// simplemente decrementamos el tope hasta llegar a la marca
	while ( TS[TOPE - 1].entrada != marca && TOPE > 0 ){
		TOPE--;
	}

	// tambien eliminamos la marca
	TOPE--;

}

// funcion para añadir un subprograma
void TS_InsertaSUBPROG(atributos atributo){

	// buscamos si ya está añadida una entrada con el mismo lexema
	dtipo tipo_buscar = encontrarEntrada(atributo.lexema, false);

	// si no lo ha encontrado, lo añadimos
	if ( tipo_buscar == desconocido ){
		// sera una funcion, en principio con 0 parametros, y del tipo leido temporalmente
		entradaTS nueva_entrada;

		nueva_entrada.entrada = funcion;

		nueva_entrada.nombre = atributo.lexema;

		nueva_entrada.parametros = 0;

		nueva_entrada.tipoDato = tipoTmp;

		TS[TOPE] = nueva_entrada;

		incrementaTOPE();

	} else {
		// si lo ha encontrado en la tabla de simbolos, imprime un error por la
		// redefinicion
		printf("\nError semantico en la linea %d. Redefinición de '%s'\n", num_linea, atributo.lexema.c_str());
	}

	// volcamos la pila de parametros, dejamos TOPE_PARAMF ya que necesitamos
	// añadir los parametros como si fueran variables al comenzar el bloque
	// la pila de paramtros se vaciará al meter la marca de bloque, ya que
	// necesitamos meter los parametros como variables
	int num_params = TOPE_PARAMF;
	// TOPE-1 es la funcion, así que antes de meter los parametros establecemos
	// el número de parámetros que tiene
	TS[TOPE - 1].parametros = num_params;
	while (num_params > 0){
		TS[TOPE] = TS_paramf[num_params - 1];

		num_params--;
		incrementaTOPE();
	}


}

// insertamos un parametro formal, utilizaremos una pila auxiliar
// ya que si no introducirá los parametros antes del subprograma
void TS_InsertaPARAMF(atributos atributo){

	bool encontrado = false;

	int n_params = TOPE_PARAMF - 1;

	// buscamos si ya existe un parametro con ese nombre
	while ( n_params > 0 && !encontrado ) {

		encontrado = atributo.lexema == TS_paramf[n_params].nombre;

		n_params--;
	}

	// si no existe lo añadimos
	if ( !encontrado ) {

		entradaTS nueva_entrada;

		nueva_entrada.entrada = parametro_formal;

		nueva_entrada.nombre = atributo.lexema;

		nueva_entrada.parametros = 0;

		nueva_entrada.tipoDato = tipoTmp;

		TS_paramf[TOPE_PARAMF] = nueva_entrada;

		TOPE_PARAMF++;

	} else {
		// si existe lo añadimos
		printf("Error semantico en la linea %d: El parámetro %s ya existe\n", num_linea, atributo.lexema.c_str());
	}

}


// funcion para encontrar una entrada en toda la pila
// muchas veces no la usamos porque solo buscamos hasta la marca anterior
dtipo encontrarEntrada(string nombre, bool quiero_que_este) {
	// devuelve la posicion de una entrada con mismo nombre, -1 si no la encuentra

	int pos_actual = TOPE - 1;
	dtipo tipo = desconocido;

	while ( TS[pos_actual].nombre != nombre && pos_actual >= 0 ) {
		// son distintos, seguimos buscando
		pos_actual-- ;
	}

	// si lo encontramos, devolvemos el tipo encontrado
	if ( pos_actual != -1 ) {
		tipo = TS[pos_actual].tipoDato;
	} else if (quiero_que_este) {
		printf("\nError semantico en la linea %d. Identificador '%s' no declarado\n", num_linea, nombre.c_str());
	}

	return tipo;

}

// incrementar el tope de la pila contemplando que se puede llenar
int incrementaTOPE(){

	int salida = 1;

	if (TOPE == MAX_TS) {
		printf("ERROR: Tope de la pila alcanzado. Demasiadas entradas en la tabla de símbolos. Abortando compilación");

		salida = 0;

	} else {
		TOPE++;
	}

	return salida;
}

// comprobamos si un lexema es de una función o no
bool esFuncion(string nombre){
	bool es_funcion = false;
	bool encontrado = false;

	int pos = TOPE - 1;

	while ( pos > 0 && !encontrado ) {
		if ( nombre == TS[pos].nombre ) {
			encontrado = true;
			es_funcion = TS[pos].entrada == funcion;
		}

		pos --;
	}

	return es_funcion;

}

// comprobamos si es una variable o parametro formal, si no lo es damos un error
void comprobarEsVarOParamametroFormal(atributos atrib) {

	// simplemente buscamos en la pila
	dtipo t = encontrarEntrada(atrib.lexema, true);

	// y si es desconocido, no asignado, o una funcion, damos el error
	if ( t == desconocido || t == no_asignado || esFuncion(atrib.lexema) ){
		printf("Error semantico en la linea %d: Solo se puede ejecutar la orden sobre variables o parametros formales.\n", num_linea);
	}
}

// comprobamos si dos tipos coinciden, y si no mostramos un error
void comprobarEsTipo(dtipo tipo, atributos atrib){
	if (atrib.tipo != tipo) {

		printf("Error semantico en la linea %d: Esperado tipo %s, encontrado tipo %s\n", num_linea, tipoAstring(tipo).c_str(), tipoAstring(atrib.tipo).c_str());
	}
}

// funcion para pasar el tipo a string, para usarlo en mensajes de salida
string tipoAstring(dtipo tipo){

	string tipo_str = "desconocido";

	if ( tipo == real ) {
		tipo_str = "real";
	} else if (tipo == entero) {
		tipo_str = "entero";
	} else if ( tipo == booleano ) {
		tipo_str = "booleano";
	} else if ( tipo == caracter ) {
		tipo_str = "caracter";
	} else if ( tipo == lista ) {
		tipo_str = "lista";
	}

	return tipo_str;
}

