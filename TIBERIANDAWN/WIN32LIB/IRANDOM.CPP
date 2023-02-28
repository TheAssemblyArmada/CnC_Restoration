/***************************************************************************
 **   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : LIBRARY                                  *
 *                                                                         *
 *                    File Name : IRANDOM.C                                *
 *                                                                         *
 *                   Programmer : Barry W. Green                           *
 *                                                                         *
 *                  Last Update : 10 Feb, 1995     [BWG]                   *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include <stdlib.h>
#include <time.h>
#include "misc.h"



/* IRANDOM ----------------------------------------------------------

   IRandom returns a random value between min and max inclusive.

   INPUTS:	int min and int max

   RETURNS:	int random number
*/

int IRandom(int minval, int maxval)
{
	int num,mask;

	// Keep minval and maxval straight.
	if (minval > maxval) {
		minval ^= maxval;
		maxval ^= minval;
		minval ^= maxval;
	}

	mask = Get_Random_Mask(maxval - minval);

	while( (num = (rand() & mask) + minval) > maxval ) ;
	return(num);
}
