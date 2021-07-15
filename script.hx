// --- Local variables ---
var hornZones = [getZone(71), getZone(140), getZone(126), getZone(78), getZone(84), getZone(109), getZone(118)];
var yggdrasilZone = getZone(101);
var zonesToCapture = 7; // number of zones to capture for victory
var capturedHorns = 0;

// --- Attack variables
var zoneAttackThreshold = 3; // starting with this many zones, wolfs begin their attack
var currentWave = 0;
var waveSpeed = 120;

// --- Script code ---
function init() {
	if (state.time == 0) {
		removeUnwantedVictories();
		if (isHost()) {
			setObjectives();
			revealHorns();
		}

		// for debugging purposes
		// me().discoverAll();
	}
}

// Regular update is called every 0.5s
function regularUpdate (dt : Float) {
	if (isHost()) {
		checkVictoryProgress();
		checkMonsterSpawn();
	}
}

// --- Launch ---

function removeUnwantedVictories() {
	//In Kinder des Waldes, you win by colonizing all fields with the Horn of Managarm
	state.removeVictory(VictoryKind.VFame);
	state.removeVictory(VictoryKind.VHelheim);
	state.removeVictory(VictoryKind.VLore);
	state.removeVictory(VictoryKind.VMoney);
	state.removeVictory(VictoryKind.VOdinSword);
	state.removeVictory(VictoryKind.VYggdrasil);
	state.removeVictory(VictoryKind.VMilitary);
}

function setObjectives() {
	for (currentPlayer in state.players) {
		currentPlayer.objectives.add("vision", "You are a boar! You do not fish or hunt; you eat berries and mushrooms or whatever the forrest gives you. You detest everyone who builds houses or towers and prefer the pureness of forrest soil.");
		currentPlayer.objectives.add("racevictory", "One day, someone scattered your Horns of Managarm across the forrest. You want them back!");
		currentPlayer.objectives.add("foerespawn", "But be careful! The forrest does not like conquerors and keeps attacking the clan with the most land.");
		currentPlayer.objectives.add("horns", "Recovered Horns", {showProgressBar:true, visible:true});
		currentPlayer.objectives.setGoalVal("horns", zonesToCapture);
	}
}

function revealHorns() {
	for (player in state.players) {
		for (zone in hornZones) {
			player.discoverZone(zone);
		}
	}
}

// --- Victory Progress ---

function checkVictoryProgress() {
	var captured = 0;
	for (zone in hornZones) {
		// if any member of the team has captured a horn, we'll increase the counter by one
		if (zone.team != null) {
			captured = captured + 1;
		}
	}
	capturedHorns = captured;
	for (currentPlayer in state.players) {
		currentPlayer.objectives.setCurrentVal("horns", captured);
	}
	if (captured >= zonesToCapture) {
		me().customVictory("Congratulations! The forrst is now at peace again.", "You lost");
	}
}

// --- Other Methods ---

function checkMonsterSpawn() {
	 if(toInt(state.time / waveSpeed) > currentWave) {
		 currentWave++;
		 var playerWithMostZones = me();

		for (player in state.players) {
			if (playerWithMostZones.zones.length == player.zones.length) {
				// random whether to switch
				if (randomInt(2) == 1) { // is exclusive
					playerWithMostZones = player;
				}
			} else if (playerWithMostZones.zones.length <= player.zones.length) {
				// the currently evaluated player has more zones
				playerWithMostZones = player;
			}
		}

		// only attack if minimum zones reached
		if (playerWithMostZones.zones.length >= zoneAttackThreshold) {
			// calculate number of wolfes
			var amount = max(1, playerWithMostZones.zones.length * 2 - 5); // attack with at least one unit

			var args : Array<Dynamic> = [];
			args.push(playerWithMostZones.name + " has the largest territory, the forrest wants it back!");
			invokeAll("notifyMessage", args);

			// spawn attack units
			var units = yggdrasilZone.addUnit(Unit.WhiteWolf, amount);

			// add stronger enemies depending on horns
			if (capturedHorns >= 4) {
				var normalized = capturedHorns - 3;
				var amount = min(6, normalized * normalized); // attack with at most 6 units
				units = units.concat(yggdrasilZone.addUnit(Unit.Valkyrie, amount));
			}

			// tell each unit to run towards zone of enemy
			for (unit in units) {
				unit.moveToZone(playerWithMostZones.zones[0], true);
			}
		}
	}
}

// --- player specific functions

function notifyMessage(message: String) {
	me().genericNotify(message);
}