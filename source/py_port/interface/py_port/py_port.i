/*
 *	MetaCall SWIG Wrapper by Parra Studios
 *	Copyright (C) 2016 Vicente Eduardo Ferrer Garcia <vic798@gmail.com>
 *
 *	A complete infraestructure for supporting multiple langauge bindings in MetaCall.
 *
 */

#ifndef METACALL_SWIG_WRAPPER_PY_PORT_I
#define METACALL_SWIG_WRAPPER_PY_PORT_I 1

/* -- Headers -- */

#ifdef SWIG
	%module py_port

	%{
		#include <py_port/py_port.h>

		#include <metacall/metacall_api.h>
		#include <metacall/metacall.h>
		#include <reflect/reflect_value_type.h>

		#include <Python.h>
	%}

	%include <py_port/py_port.h>

	#ifndef LOADER_LAZY
		%init
		%{
			metacall_initialize();
		%}
	#endif

#endif

#ifdef __cplusplus
extern "C" {
#endif

/* -- Type Definitions -- */

typedef void * value;

/* -- Type Maps -- */

/**
*  @brief
*    Transform variadic arguments from Python into
*    a valid metacallv format with values
*/
%typemap(in) (const char * name, ...)
{
	value * argv;
	size_t argc, i;

	/* Format string */
	$1 = PyUnicode_AsUTF8($input);

	/* Variable length arguments */
	argc = PyTuple_Size(varargs);

	argv = (value *) malloc(argc * sizeof(value));

	for (i = 0; i < argc; ++i)
	{
		PyObject * o = PyTuple_GetItem(varargs, i);

		/*if (PyInt_Check(o))
		{
			argv[i] = value_create_int((int) PyInt_AsLong(o));
		}
		else */if (PyLong_Check(o))
		{
			argv[i] = value_create_long(PyLong_AsLong(o));
		}
		else if (PyFloat_Check(o))
		{
			argv[i] = value_create_double(PyFloat_AsDouble(o));
		}
		else if (PyUnicode_Check(o))
		{
			Py_ssize_t size;

			const char * str = PyUnicode_AsUTF8AndSize(o, &size);

			argv[i] = value_create_string(str, (size_t)size);
		}
		else
		{
			PyErr_SetString(PyExc_ValueError,"Unsupported argument type");

			free(argv);

			return NULL;
		}
	}

	$2 = (void *) argv;
}

/* -- Features -- */

/**
*  @brief
*    Execute the call and transform return
*    value into a valid Python format
*
*  @return
*    A value converted into Python format
*/
%feature("action") metacall
{
	size_t			i, vc;
	value		*args, ret;

	vc = PyTuple_Size(varargs);
	args   = (value *) arg2;

	/* Execute call */
	ret = metacallv(arg1, args);

	/* Clear args */
	for (i = 0; i < vc; ++i)
	{
		value_destroy(args[i]);
	}

	free(args);

	/* Return value */
	if (ret != NULL)
	{
		switch (value_type_id(ret))
		{
			case TYPE_INT :
			{
				$result = PyInt_FromLong((long)value_to_int(ret));
				break;
			}

			case TYPE_LONG :
			{
				$result = PyLong_FromLong(value_to_long(ret));
				break;
			}

			case TYPE_DOUBLE :
			{
				$result = PyFloat_FromDouble(value_to_double(ret));
				break;
			}

			case TYPE_STRING :
			{
				$result = PyUnicode_FromString(value_to_string(ret));
				break;
			}

			default :
			{
				PyErr_SetString(PyExc_ValueError, "Unsupported return type");

				$result = Py_None;
			}
		}

		value_destroy(ret);
	}
	else
	{
		$result = Py_None;
	}
}

/* -- Headers -- */

#ifdef SWIG

	%include <metacall/metacall_api.h>

	#ifdef METACALL_API
	#	undef METACALL_API
	#	define METACALL_API
	#endif

	%include <metacall/metacall.h>

#endif

#ifdef __cplusplus
}
#endif

#endif /* METACALL_SWIG_WRAPPER_PY_PORT_I */
