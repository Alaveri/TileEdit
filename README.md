
# TileEdit

Alaveri Tileset Editor is an MS-DOS real-mode application for creating and editing tile sets for games.  Uses the Alaveri Pascal Library (APL) and the Veridian UI Library.

This project is currently under development and has only limited functionality.  As Veridian is developed, the Tileset Editor is being created as a test-bed for Veridian-based applications, and should be a good reference for how to create Veridian graphical applications in Turbo Pascal 7 for DOS.

Note:  Requires the APL and Veridian to build.  To build, clone APL and Veridian, and modify the Turbo Pascal Directory Unit Directories setting to include the directories where the APL and Veridian reside.  Also modify the Include Directories to reference the APL.  Add the DOS to the Conditional Defines setting, and optionally add the Debug conditional to the list to enabled debugging, range checking, etc.  This is recommended for development.  For example enter ```dos;debug;``` to the conditional defines.
