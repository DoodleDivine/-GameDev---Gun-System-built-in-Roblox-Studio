# **Gun System**

- This system features client and server sided logic containing modules, models and UI made to feel more accurate of that to an actual gun-game.

- Explanations of the files in the repository below 👇:

## **WeaponClient** [Kept in StarterPack folder]

- Client script that includes logic such as **shoot, ammo and reload states**, **viewmodel Implementation**, **UI application**
and **sound**.

- It as well includes data that is sent to the server script via remote events for validation and back to the player
to prevent any technical errors during gameplay.

## **WeaponConfig** [Kept in StarterPack folder]

- Module script that contains configuration data such as **weapon data**, **animation data**, **sound data** and others.

- Used in **WeaponClient** to set up client and server communication to maintain a single source of truth throughout the system.

## **WeaponServer** [Kept in ServerScriptService folder]

- Server script that includes validation logic from the **WeaponClient** script. It as well helps maintain accuracy of the experience
by handling lag compensation and preventing potential exploitation when it comes to verifying shoot logic.

- Contains **damage calculation** and triggers **VFX replication** logic that is sent to the client to help visualize response to the
players` screen.

- Handles character model synchronization to display the active weapon in the 3D world from the other players` perspective.
