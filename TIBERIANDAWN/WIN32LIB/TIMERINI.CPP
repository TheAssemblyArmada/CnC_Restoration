/***************************************************************************
 **     C O N F I D E N T I A L --- W E S T W O O D   S T U D I O S       **
 ***************************************************************************
 *                                                                         *
 *                 Project Name : Temp timer for 32bit lib                 *
 *                                                                         *
 *                    File Name : TIMERINI.CPP                             *
 *                                                                         *
 *                   Programmer : Scott K. Bowen                           *
 *                                                                         *
 *                   Start Date : July 6, 1994                             *
 *                                                                         *
 *                  Last Update : July 6, 1994   [SKB]                     *
 *                                                                         *
 *-------------------------------------------------------------------------*
 * Functions:                                                              *
 *   Init_Timer_System -- Initialize the WW timer system.                  *
 *   Remove_Timer_System -- Removes the timer system.                      *
 * - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - */

#include <wwstd.h>
#include <mmsystem.h>
#include "timer.H"
#include <profile.h>
#include <stdio.h>

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// Defines /////////////////////////////////////

#define COPY_FROM_MEM	TRUE

/////////////////////////////////////////////////////////////////////////////////
////////////////////////////// timera.asm functions//////////////////////////////

#ifdef __cplusplus
extern "C" {
#endif

extern BOOL Install_Timer_Interrupt(VOID *bin_ptr, UINT rm_size, UINT freq, BOOL partial);
extern BOOL Remove_Timer_Interrupt(VOID);

#ifdef __cplusplus
}
#endif

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////// Global Data /////////////////////////////////////

BOOL	TimerSystemOn	= FALSE;

// Global timers that the library or user can count on existing.
TimerClass					TickCount(BT_SYSTEM);
CountDownTimerClass		CountDown(BT_SYSTEM, 0);


// Prototype for timer callback
void CALLBACK Timer_Callback ( UINT event_id, UINT res1 , DWORD user, DWORD  res2, DWORD  res3 );

HANDLE	TimerThreadHandle = 0;		//Handle of timer thread
int		InTimerCallback	= 0;		//Flag to say if we are in a timer callback

/////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////// Code ////////////////////////////////////////



#pragma warning (disable : 4996)


/***************************************************************************
 * WinTimerClass::WinTimerClass -- Initialize the WW timer system.         *
 *                                                                         *
 *                                                                         *
 * INPUT: UINT : user timer frequency.												  *
 *                                                                         *
 * OUTPUT:                                                                 *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   10/5/95 3:47PM : ST Created.                                          *
 *=========================================================================*/
WinTimerClass::WinTimerClass (UINT freq, BOOL partial)
{
	BOOL		success;

	//
	// Inform windows that we want a higher than normal
	// timer resolution
	//
#ifdef __SW_EP
	timeBeginPeriod(1000/PROFILE_RATE);
	Frequency = PROFILE_RATE;
#else
	timeBeginPeriod ( 1000/freq );
	Frequency = freq;
#endif

	SysTicks = 0;
	UserTicks = 0;

	//
	// Install the timer callback event handler
	//
	TimerHandle = timeSetEvent ( 1000/freq , 1 , Timer_Callback , 0 , TIME_PERIODIC);
	TimerSystemOn = success = ( TimerHandle !=0 );

	if (success)  {
		if (!partial) {
			WindowsTimer=this;
			TickCount.Start();
		}
	}else{
		char error_str [128];
		sprintf (error_str, "Error - timer system failed to start. Error code %d\n", GetLastError());
		OutputDebugString(error_str);
	}
}



/***************************************************************************
 * WinTimerClass::~WinTimerClass -- Removes the timer system.              *
 *                                                                         *
 *                                                                         *
 * INPUT:   NONE.                                                          *
 *                                                                         *
 * OUTPUT:  BOOL was it removed successfuly                                *
 *                                                                         *
 * WARNINGS:                                                               *
 *                                                                         *
 * HISTORY:                                                                *
 *   10/5/95 3:47PM : ST Created.                                          *
 *=========================================================================*/
WinTimerClass::~WinTimerClass( void )
{

	if ( TimerHandle ){
		timeKillEvent ( TimerHandle );
	}

	TimerSystemOn = FALSE;
	timeEndPeriod ( 1000/Frequency );
}





/***********************************************************************************************
 * Timer_Callback -- Main timer callback. Equivalent to a timer interrupt handler              *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    uint timer ID                                                                     *
 *           uint reserved                                                                     *
 *           long 0 (application defined)                                                      *
 *           long reserved                                                                     *
 *           long reserved                                                                     *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    10/5/95 3:19PM ST : Created                                                              *
 *=============================================================================================*/


void CALLBACK Timer_Callback (UINT , UINT , DWORD , DWORD , DWORD)
{
	//CONTEXT	context;

	InTimerCallback++;
	
	if (!TimerThreadHandle){
		DuplicateHandle (GetCurrentProcess(), GetCurrentThread() , GetCurrentProcess() ,&TimerThreadHandle , 0 , TRUE , DUPLICATE_SAME_ACCESS);
	}


	if (WindowsTimer) {
		WindowsTimer->Update_Tick_Count();
	}
	InTimerCallback--;
}






/***********************************************************************************************
 * WinTimerClass::Update_Tick_Count -- update westwood timers                                  *
 *                                                                                             *
 *                                                                                             *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   Nothing                                                                           *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    10/5/95 3:58PM ST : Created                                                              *
 *=============================================================================================*/

void WinTimerClass::Update_Tick_Count ( void )
{
/*
 *
 *  Increment westwood timers
 *
 */
	SysTicks++;
	UserTicks++;

}








/*
;***************************************************************************
;* GET_NUM_INTERRUPTS -- Returns the number of interrupts that have occured*
;*                                                                         *
;* INPUT: TRUE - returns num RM ints.                                      *
;*        FALSE - return num PM ints.                                      *
;*                                                                         *
;* OUTPUT:                                                                 *
;*                                                                         *
;* WARNINGS:                                                               *
;*                                                                         *
;* HISTORY:                                                                *
;*   07/12/1994 SKB : Created.                                             *
;*=========================================================================*
	PROC	Get_Num_Interrupts C Near
	USES	esi
	ARG	realmode:DWORD

	mov	esi,[RealModePtr]
	cmp	[realmode],0
	je	??prot_mode
	mov	eax,[(TimerType PTR esi).NumRMInts]
	ret
??prot_mode:
	mov	eax,[(TimerType PTR esi).NumPMInts]
	ret

	ENDP
  */




/***********************************************************************************************
 * WinTimerClass::Get_System_Tick_Count -- returns the system tick count                       *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   tick count                                                                        *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    10/5/95 4:02PM ST : Created                                                              *
 *=============================================================================================*/

unsigned WinTimerClass::Get_System_Tick_Count ( void )
{
	return ( SysTicks );
}



/***********************************************************************************************
 * WinTimerClass::Get_User_Tick_Count -- returns the user tick count                           *
 *                                                                                             *
 * INPUT:    Nothing                                                                           *
 *                                                                                             *
 * OUTPUT:   tick count                                                                        *
 *                                                                                             *
 * WARNINGS: None                                                                              *
 *                                                                                             *
 * HISTORY:                                                                                    *
 *    10/5/95 4:02PM ST : Created                                                              *
 *=============================================================================================*/

unsigned WinTimerClass::Get_User_Tick_Count ( void )
{
	return ( UserTicks );
}
