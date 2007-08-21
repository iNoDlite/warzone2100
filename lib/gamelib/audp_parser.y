/*
	This file is part of Warzone 2100.
	Copyright (C) 1999-2004  Eidos Interactive
	Copyright (C) 2005-2007  Warzone Resurrection Project

	Warzone 2100 is free software; you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation; either version 2 of the License, or
	(at your option) any later version.

	Warzone 2100 is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with Warzone 2100; if not, write to the Free Software
	Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA
*/
%{

#include "lib/framework/frame.h"
#include "lib/gamelib/parser.h"
#include "lib/sound/audio.h"
#include "lib/gamelib/anim.h"

static int		g_iCurAnimID = 0;
static Vector3i vecPos, vecRot, vecScale;

int audp_lex();
void audp_error(char *pMessage,...);

%}

%name-prefix="audp_"

%union {
	float		fval;
	long		ival;
	signed char	bval;
	char		sval[100];
}

	/* value tokens */
%token <fval> FLOAT_T
%token <ival> INTEGER
%token <sval> QTEXT /* Text with double quotes surrounding it */
%token <ival> LOOP
%token <ival> ONESHOT

	/* keywords */
%token AUDIO
%token ANIM3DFRAMES
%token ANIM3DTRANS
%token ANIM3DFILE
%token AUDIO_MODULE
%token ANIM_MODULE
%token ANIMOBJECT

	/* module names */

%%

data_file:				module_file | anim_file
						;

module_file:			module_file data_list |
						data_list
						;

data_list:				audio_module | anim_module
						;

audio_header:			AUDIO_MODULE '{'
						;

audio_module:			audio_header audio_list '}' |
						audio_header  '}'
						;

audio_list:				audio_list audio_track |
						audio_track
						;
	/*
	 * unsigned int audio_SetTrackVals(const char* fileName, BOOL loop, unsigned int volume, unsigned int audibleRadius)
	 */

audio_track:			AUDIO QTEXT LOOP INTEGER INTEGER
						{
							audio_SetTrackVals( $2, TRUE, $4, $5 );
						}
						| AUDIO QTEXT ONESHOT INTEGER INTEGER
						{
							audio_SetTrackVals( $2, FALSE, $4, $5 );
						}
						;

anim_module_header:		ANIM_MODULE '{'
						{
						}
						;

anim_module:			anim_module_header anim_file_list   '}' |
						anim_module_header anim_config_list '}'
						/* NULL */
						;

anim_config_list:		anim_config_list anim_config |
						anim_config
						/* NULL */
						;

anim_file_list:			anim_file_list anim_file |
						anim_file
						/* NULL */
						;

/*
anim_file:				ANIM3DFILE QTEXT INTEGER
						{
							g_iCurAnimID = $3;
							IncludeFile( $2 );
						}
						anim_trans | anim_frames
						;
*/

anim_file:				anim_trans | anim_frames
						;

anim_config:			QTEXT INTEGER
						{
							g_iCurAnimID = $2;
							anim_SetVals( $1, $2 );
						}
						;

	/*
	 * anim_Create3D( char szAniFileName[], char szPieFileName[], UWORD uwFrames,
	 *					UWORD uwFrameRate, UWORD uwNumObj, char cType, UWORD uwID )
	 */

anim_trans:				ANIM3DTRANS QTEXT INTEGER INTEGER INTEGER
						{
							anim_Create3D( $2, $3, $4, $5, ANIM_3D_TRANS, g_iCurAnimID );
						}
						'{' anim_obj_list '}'
						{
							g_iCurAnimID++;
						}
						;

anim_frames:			ANIM3DFRAMES QTEXT INTEGER INTEGER
						{
							anim_Create3D( $2, $3, $4, 1, ANIM_3D_FRAMES, g_iCurAnimID );
						}
						'{'
						{
							anim_BeginScript();
						}
						anim_script '}'
						{
							anim_EndScript();
							g_iCurAnimID++;
						}
						;

anim_obj_list:			anim_obj anim_obj_list |
						anim_obj
						;

anim_obj:				ANIMOBJECT INTEGER QTEXT '{'
						{
							anim_BeginScript();
						}
						anim_script '}'
						{
							anim_EndScript();
						}
						;

anim_script:			anim_script anim_state |
						anim_state
						;

anim_state:				INTEGER INTEGER INTEGER INTEGER INTEGER INTEGER INTEGER INTEGER INTEGER INTEGER
						{
							vecPos.x   = $2;
							vecPos.y   = $3;
							vecPos.z   = $4;
							vecRot.x   = $5;
							vecRot.y   = $6;
							vecRot.z   = $7;
							vecScale.x = $8;
							vecScale.y = $9;
							vecScale.z = $10;
							anim_AddFrameToAnim( $1, vecPos, vecRot, vecScale );
						}
						;

%%

/***************************************************************************/
/* A simple error reporting routine */

void audp_error(char *pMessage,...)
{
	int		line;
	char	*pText;
	char	aTxtBuf[1024];
	va_list	args;

	va_start(args, pMessage);
	vsprintf(aTxtBuf, pMessage, args);
	va_end(args);

	parseGetErrorData( &line, &pText );
	debug( LOG_ERROR, "RES file parse error:\n%s at line %d\nToken: %d, Text: '%s'\n", aTxtBuf, line, audp_char, pText );
	abort();
}

/***************************************************************************/
/* Read a resource file */
BOOL ParseResourceFile(PHYSFS_file* fileHandle)
{
	// Tell lex about the input file
	parserSetInputFile(fileHandle);

	audp_parse();

	return TRUE;
}

/***************************************************************************/
