# **Gun System**

- This system features client and server sided logic containing modules, models and UI made to feel more accurate of that to an actual gun-game.

- Explanations of the files in the repository below 👇:

## **WeaponClient** [Kept in StarterPack folder]

- Client script that includes logic such as **shoot, ammo and reload states**, **viewmodel Implementation**, **UI application**
and **sound**

- It as well includes data that will be sent to the server script for validation and back to the player to prevent any technical
errors during gameplay.

## **WeaponConfig** [Kept in StarterPack folder]

- Module script that contains configuration data such as **weapon data**, **animation data**, **sound data** and others.

- Used in **WeaponClient** to set up client and server communication to maintain a single source of truth throughout the system.
