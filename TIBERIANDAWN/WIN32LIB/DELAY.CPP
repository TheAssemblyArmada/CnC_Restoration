/***************************************************************************
 **   C O N F I D E N T I A L --- W E S T W O O D   A S S O C I A T E S   **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : LIBRARY                                  *
 *                                                                         *
 *                    File Name : DELAY.C                                  *
 *                                                                         *
 *                   Programmer : Christopher Yates                        *
 *                                                                         *
 *                  Last Update : 27 March, 1991   [CY]                    *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include	"wwstd.h"
#include <timer.h>

void Delay(int duration)
{
	unsigned long count;
	TimerClass timer(BT_SYSTEM,TRUE);

	while (duration--) {
		count = timer.Time() + 1L;
		while (count >= (unsigned)timer.Time()) {
			;
		}
	}

#if(FALSE)
	while (duration--)
		Wait_Vert_Blank(VertBlank);
#endif
}

#if(FALSE)
void Vsync()
{
	Wait_Vert_Blank(VertBlank);
}
#endif
