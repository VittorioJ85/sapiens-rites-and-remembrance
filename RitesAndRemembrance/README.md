# Rites and Remembrance

Version 0.9.1 — Author: Vittorio

## Tribal Ceremony

After discovering Rites and Remembrance, select one object or ground location and choose **Gather for Tribal Ceremony** in its circular action menu. The gathering place must be within 200 metres of an eligible tribe member. An overhead diagram shows the planned standing places before any activities are interrupted. Gold marks the centre; blue marks participants. This is a formation diagram, not a 3D world overlay.

At least **25 living tribe members** are required. Choose **Radius Select** or **Box Select** in the preview, then drag to select standing places. The mouse wheel adjusts the radius. Blue places are selected; grey places are excluded. The count, percentage and expected reward update immediately. **Gather Selected** interrupts ordinary work for the selected members. Sapiens with incapacitating conditions, active fights/flights, falls or existing remembrance visits are excluded. Ordinary tiredness no longer cancels ceremony orders; native danger and pathfinding rules remain active. Babies are not separate walking participants in the native tribe roster.

Participants occupy distinct positions facing the centre. Larger tribes use concentric rings; blocked, underwater or steep positions are skipped. The current limit is 512 participants. A site without enough safe positions is rejected. Physics checks standing room before summoning; actual pathfinding happens as each participant travels.

The panel shows **Gathering: arrived / expected**. A lost summons is retried automatically up to twice, at least 15 simulation seconds apart. **Invite Again** allows further attempts for missing selected members after the same delay. Valid journeys and waiting participants are never restarted, and emergencies are not overridden. The dance starts automatically when everyone selected reaches their place. **Begin with Those Present** starts with those already there and releases outstanding summons; **Cancel Ceremony** releases this ceremony's orders without cancelling replacement jobs. Gathering times out after 300 simulation seconds without a reward. Closing the panel does not cancel the ceremony; reopen it through the radial entry at any selectable object or ground location. The panel does not pause the game.

Only members who complete the full **30 simulation seconds** of shared dancing receive **Tribal Unity**. If someone leaves or is interrupted, the remaining dancers can still finish. Attendance is measured against the whole living tribe, including members not selected or unable to attend.

| Completed attendance | Happiness / Loyalty | Work speed | Duration |
| --- | --- | --- | --- |
| More than 50% (including 51% and 100%) | +2 / +2 | Attendance percentage × 0.2, rounded to a whole percent | 3 game days |
| Exactly 50% | +1 / +1 | +10% | 3 game days |
| At least 25%, below 50% | +1 / +1 | Attendance percentage × 0.2, rounded to a whole percent | 1 game day |
| Below 25% | No bonus | No bonus | — |

For example, 100% attendance grants +20% work speed, 75% grants +15%, and 60% grants +12%. Mood stars remain capped at five. A death or departure during the ceremony does not inflate the percentage; new tribe members increase the denominator. A tribe falling below 25 members cannot receive a new reward. Duration uses the world's day length at completion, is saved by the native effect timer and pauses with simulation. Later day-length changes do not resize an existing effect. Existing version 0.8.0 bonuses retain their original strength and remaining duration until they expire.

Each tribe may hold a ceremony **once per full game year**, measured from the start of the dance using the world's configured year length. Cancelling or timing out while gathering does not consume the yearly ceremony. Once dancing starts, cancellation or attendance below the reward threshold still consumes it. The saved deadline survives reloads and does not change when time settings are subsequently edited. A retained ceremony from an older mod version is counted from its recorded dance start. The panel reports the remaining wait when another ceremony is requested. An active Tribal Unity reward also prevents another ceremony, even with an unusually short custom year. Rewards do not stack or refresh. Productive crafting, building, gathering, digging, chopping and mining actions receive the speed multiplier; movement, research, combat, needs and effect timers retain their normal rate. Existing family rewards and relationship behavior remain unchanged.

Automated lifecycle, UI-routing, animation and regression checks passed against the separately selected Public and Unstable installations. Both local executables currently identify as **0.7.0.2**. Full in-game formation/pathfinding, rendering and multiplayer validation remains required; these tests do not establish compatibility with every older release or third-party mod combination.

## Earlier updates

Version 0.7.2 bounds client waiting for memorial and remembrance requests to ten seconds. If the server does not reply, the UI reports that the outcome is unknown and becomes usable again. No write is retried automatically; close the dialog and let the next poll retrieve the saved decision. Late or duplicate replies cannot replay UI transitions. The optional family panel invalidates pending replies and cached views when its inspector is reloaded.

Version 0.7.1 contains only **Gravestone**, **Funerary Urn** and **Personal Memorial**. Grave Slab and Grave Stele definitions, models, recipes and preview components have been removed completely. Saves containing those removed objects or their construction orders are no longer supported by this version; use the backed-up 0.7.0 for those saves. Unplaced unknown selections return to selection. The new illustrated cover remains promotional artwork; in-game previews show native resource geometry.

Version 0.6.7 fixes the startup failure reported on Public 0.6.1.3 when `crouchLow` is absent. Remembrance selects available native crouching/seated poses, with a standing fallback, while retaining its eight-second duration. English research localization keys are now supplied for older research registries.

Version 0.6.6 keeps the memorial information panel open after a remembrance action so its server response remains visible. It explains when no living relatives are available in your tribe, when all living relatives already have a remembrance bonus, or when another condition prevents attendance. For a family ceremony, an active bonus identifies the relative who must wait. Messages appear below the memorial's name and age; selecting another object or closing the panel clears them.

Version 0.6.5 keeps the Family Tree content visible when opened from a grave's radial menu. The native post-click dismissal now closes only the action wheel while that family panel is open. Other radial actions retain their normal behavior. The safe modal lifecycle introduced in 0.6.4 is preserved.

Version 0.6.4 fixes an unsafe Family Tree window lifecycle: closing the inspector could delete a window still referenced by Sapiens, causing a later window switch to access it. The optional family panel now retains and reuses one container per inspector and invalidates pending replies when closed. Native lifecycle regression tests pass; confirmation in the running game remains required.

Version 0.6.3 moves **Remember Ancestors**, **Remember Ancestors Together** and the optional **Family Tree** link into the circular action menu. The compact information panel expands to fit the full memorial title and age, and shows action feedback without the former buttons. The animation crash fix, duplicate-click protection, work interruption and all existing rewards are retained.

Build a personal memorial for a deceased member of your tribe using the game's original resources.

## Use

1. Enable **Rites and Remembrance** for your world and discover it after **Digging** (see Research below).
2. A death opens a Yes/No dialog once the gameplay screen can safely show it. The game pauses throughout the dialog, design selection and material selection.
3. Choose **Yes**, then select a memorial using its model preview and material costs.
4. Select each material category and use the native **Use only** controls to allow the exact variants you want. Native 3D previews show the complete memorial, including its base. In material selection, Use only immediately updates the preview using the selected resource geometry and native materials. If several variants remain allowed, the preview follows the same first-allowed ordering as native building previews; workers may use any allowed variant. World lighting can differ.
5. Choose **Place build order**, then position and rotate it using normal placement controls. Closing the dialog restores the previous speed; a previously paused game remains paused.
6. Your tribe delivers the selected resources and completes the construction order using the Rites and Remembrance role.
7. Select the memorial to see the deceased person's name, age and saved portrait. **Family Tree** opens the deceased person's family when the compatible Family Tree mod is enabled for this world.
8. Use **Deconstruct** to remove the memorial through the normal construction/deconstruction system.
9. At a completed grave, use **Remember Ancestors** or **Remember Ancestors Together** in the circular action menu. The optional **Family Tree** entry is also available there.

| Memorial | Required resources | Arrangement |
|---|---|---|
| Gravestone | 4 Soil / Sand / Clay; 1 large soft or hard rock | Four earth decorations with a rock above |
| Funerary Urn | 3 tiles; 1 urn | Three vertically stacked tiles beneath the urn |
| Personal Memorial | 1 known resource object | The selected item itself, preserved as a named memorial |

Tiles may be fired, unfired dry or unfired wet. Urns may be fired, unfired dry or unfired wet. Restrictions apply to the build order; leaving multiple variants enabled lets workers choose among them.

**No** permanently declines the memorial. Escape postpones the question for 30 seconds. Cancelling placement returns to selection. Unfinished decisions persist with the world. One memorial order is allowed per recorded death; cancelling a placed order or demolishing it does not create a new decision.

## Personal Memorial

**Personal Memorial** lets you choose exactly one known, deliverable resource object: for example an apple, a stone block, a tool or an urn. The scrollable list includes compatible resource objects from enabled mods and shows a live preview. Workers deliver one instance of that exact type. Names, portraits, family effects and demolition work as for the other graves. Living beings, terrain and whole buildings are not deliverable items. The memorial preserves its item's appearance without remaining an edible or usable loose resource. Its generic placement footprint is small; large objects can extend beyond that footprint, so leave surrounding space.

## Remember Ancestors

Select one completed family grave and click **Remember Ancestors** in its circular action menu. The server chooses the nearest eligible relative from the saved family record and cancels their current activity, including work, delivery, sleep or another ordinary/modded order. They do not have to be idle. Family Tree is not required. The information panel shows confirmation or explains why the action could not start.

The relative uses native pathfinding to approach the grave, then performs an eight-second remembrance sequence: lowering into a seated pose, pausing quietly and rising again. This new sequence reuses native skeleton poses and supports adult male/female and boy/girl animation groups. Interrupted or unreachable visits give no bonus; demolishing the grave cancels a visit.

A completed visit gives that relative **+1 Happiness for 1,000 simulation seconds**, with no Tribe Loyalty bonus. This visit effect does not stack or refresh while active, including visits to other family graves. After it expires, another visit is possible. It can coexist with burial comfort or demolition grief, subject to native mood limits. Old records without a family snapshot cannot identify eligible visitors.

## Remember Ancestors Together

Select one completed grave and use **Remember Ancestors Together** in its circular action menu. All known living relatives of the deceased in your tribe are summoned, using the family snapshot captured at death. Their current orders are cancelled through the game's normal cancellation mechanism. There is no idle requirement or activity allowlist. Sleeping participants wake, seats and hauling assignments are released, and held objects are dropped into the world before travelling to the grave. Manual work assignments are cleared so they cannot immediately reclaim a participant.

Physical inability to work, an ongoing fall, an existing remembrance visit or an active visit bonus still prevents attendance. The panel identifies a blocking relative before cancelling anyone's work. Ordinary tiredness does not cancel the new ceremony order. Native reactions to immediate danger still apply and may interrupt the gathering. Existing visit bonuses are not refreshed by summoning again.

Early arrivals wait at the grave. Once everyone has arrived, the family starts the eight-second remembrance animation together. Successful completion gives every participant **+1 Happiness and +1 Tribe Loyalty for 2,000 simulation seconds**, twice the individual visit's duration. The individual and collective visit bonuses cannot stack or refresh each other. Burial comfort and demolition grief remain separate effects, with the usual mood limits.

Each participant also gains **+0.1 short-term bond and +0.1 relationship mood toward every other participant**, using the native social function and its 0–1 limits. Both directions improve; long-term relationships evolve through the normal game simulation. This does not create partnerships or change family relationships. A lone surviving relative can remember, but has no other participant with whom to strengthen a relationship.

The ceremony is cancelled without rewards if a participant's order is interrupted, a relative leaves or dies, the grave is removed, or the family cannot assemble within 300 simulation seconds. Nobody receives a partial completion bonus. Ceremony state and effect timers are saved; simulation pause also pauses their time. Older graves without family records cannot identify participants.

## Research

The research tree contains **Rites and Remembrance** directly after **Digging**, with an arched memorial icon. Research requires Digging and a recorded death in your tribe. Select **Soil or Clay** and use Investigate. The native research job uses four units of Soil / Clay; no urn, tile, flower or corpse is required.

Only deaths occurring **after discovery** create memorial decisions. Earlier deaths count as the research prerequisite but never become a backlog. Updating from older versions skips their pending decisions in one step; built graves and completed records remain intact. A brief research notice may appear once per session before discovery, without a materials list.

Each design becomes selectable when the tribe has discovered at least one suitable material type for every ingredient category. This uses the game's persistent resource-discovery state: running out of stock does not relock a design. Workers still need to deliver the actual quantities. Locked designs remain visible with an unlock hint.

When Hammerstone is enabled for the world, its Mod Options window contains a Rites and Remembrance information page. The mod also works without Hammerstone.

## Family benefit

Completing a grave gives its deceased person's known living relatives in the same tribe **+1 Happiness and +1 Tribe Loyalty for 1,000 simulation seconds**, matching the native fixed-duration positive events for having a child and learning a skill. The family snapshot uses native family and partner relationships recorded at death, without requiring Family Tree. **Family Remembered** contributes to normal mood updates while active. Contributions from different graves expire independently and stack up to five levels. Other positive and negative status effects still apply; displayed moods follow the game's normal adjustment rules.

Actually removing a completed grave gives its known living relatives in the same tribe **-1 Happiness and -1 Tribe Loyalty for 2,000 simulation seconds**. It also ends any remaining comfort from that particular grave. **Family Memorial Demolished** penalties expire independently, with a maximum of five levels. Merely scheduling/cancelling demolition, or cancelling an unfinished construction order, does not apply the penalty. Native demolition and immediate removal of legacy graves are supported. Each deceased person's grave can grant comfort and a demolition penalty only once.

Timers pause with the simulation, follow its speed and retain their remaining duration across saves. Previously permanent comfort effects receive one full 1,000-second interval on their first simulation update after upgrading; they do not refresh on later loads. Existing graves are not rewarded retroactively, and old death records lacking family snapshots cannot identify recipients.

## Existing saves and optional integration

- Existing memorials retain their IDs and names and use the updated designs. No materials are charged retroactively.
- Old, instantly placed memorials without construction metadata are removed immediately by Deconstruct and return no resources. New memorials use native jobs and native material recovery.
- Portraits are captured for deaths recorded by version 0.2.0 onward. Earlier records lack appearance data and cannot display the original portrait.
- Records start when this mod is enabled. Earlier deaths are not imported from Family Tree.
- Family Tree is optional. Its button appears only when enabled. The integration targets this project's Family Tree interface; unrelated genealogy mods are not automatically supported.
- Names appear in the inspection panel, not engraved into the mesh.

## Installation

Copy RitesAndRemembrance to %APPDATA%\majicjungle\sapiens\mods for the unstable installation, or %APPDATA%\majicjungle\sapiens_NICHT_BETA\mods for this project's Public installation, then enable it for the desired world. Keep the two user-data directories separate. Restart Sapiens after an update. Installing files does not automatically enable the mod in existing worlds.

## Validation

Offline checks compile Lua with the installed game's LuaJIT library and exercise queue persistence, authorization, material restrictions, popup transitions, pause restoration, native build routing, portrait persistence, demolition and optional Family Tree navigation. Model checks verify resource counts and finite transforms.

Engine interfaces are simulated. In-game rendering, research progression, worker construction, terrain placement, save/reload and multiplayer still require live verification. preview.png is promotional artwork, exported as a 768 × 768 PNG below 1 MB. Development reference rendering does not overwrite that cover. Selection and Breakthrough previews use centered native meshes with original texture coordinates and materials. Material selection uses native composite models assembled from prepositioned resource groups. All variants share one padded frame.

See DEVELOPMENT.md for implementation details.
