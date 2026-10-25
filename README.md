# **Gun System** 🔫

- This system features client and server sided logic containing modules, models and UI made to feel more accurate of that to an actual gun-game.

- Explanations of the files in the repository below 👇:

## **WeaponClient** 💻 [Kept in StarterPack folder]

- Client script that includes logic such as **shoot, ammo and reload states**, **viewmodel Implementation**, **UI application**
and **sound**.

- It as well includes data that is sent to the server script via remote events for validation and back to the player
to prevent any technical errors during gameplay.

## **WeaponConfig** ⚙️ [Kept in StarterPack folder]

- Module script that contains configuration data such as **weapon data**, **animation data**, **sound data** and others.

- Used in **WeaponClient** to set up client and server communication to maintain a single source of truth throughout the system.

## **WeaponServer** 🌐 [Kept in ServerScriptService folder]

- Server script that includes validation logic from the **WeaponClient** script. It as well helps maintain accuracy of the experience
by handling lag compensation and preventing potential exploitation when it comes to verifying shoot logic.

- Contains **damage calculation** and triggers **VFX replication** logic that is sent to the client to help visualize response to the
players` screen.

- Handles character model synchronization to display the active weapon in the 3D world from the other players` perspective.

<img width="400" height="265" alt="For GitHub2" src="https://github.com/user-attachments/assets/eda19901-1eff-4ede-9a6c-6437a7a97cab" />

## **ClientReplicator** 💻 [Kept in StarterPlayer - StarterPlayerScripts folder]

- Simple Client script that handles **VFX replication** with data that has been collected via remote events.

- Makes use of weapon model's muzzle to replicate the bullet trail to the hit target.

# **Evaluation** 🤔

- Throughout developing this system, my main issue was handling the ray cast logic.

- Complications ocurred such as delayed output when input was clearly well placed,
and the direction of the bullet trail VFX not actually hitting the position of where
the player's body was aiming at.

- However, I did find the problem, and it was where I was defining the origin positions.
I defined them in the server's model instead of the client first, resulting in information
being sent from client to server, then getting the server data and applying the ray cast.

- I fixed this by **defining and creating the ray cast on the client**, then fetched the position
of the ray cast and triggered VFX replication to follow that position.

- Video that explains my problem: https://www.youtube.com/shorts/pqSYSv_KLMQ

- There was also the issue with the **Headshot** logic, where it wouldn't work when accessories were
equipped on the head but it's also related to ray cast and the quick fix was ignoring accessories
when the ray cast was running.

<img width="400" height="207" alt="For Github3" src="https://github.com/user-attachments/assets/dfcf2e81-2389-48a1-bc38-c23038c7671c" />

# **Small showcase of the system**

<img width="400" height="207" alt="For GitHub" src="https://github.com/user-attachments/assets/909b3726-fceb-461e-800a-eef65be80d66" />
