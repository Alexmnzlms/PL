#ifndef ESTRUCTURAS_DATOS
#define ESTRUCTURAS_DATOS

#include <string>

using namespace std;

typedef enum {
	// marca comienzo de bloque
	marca,
	// subprograma
	funcion,
	// si es variable
	variable,
	// si es un parametro formal
	parametro_formal
} tipoEntrada;


typedef enum {
	entero,
	real,
	caracter,
	booleano,
	vacio,
	desconocido,
	no_asignado
} dtipo;

typedef struct {
	tipoEntrada entrada;
	string nombre;
	dtipo tipoDato;
	bool es_lista;
	unsigned int parametros;
	int tamDimen;
} entradaTS ;


#endif



