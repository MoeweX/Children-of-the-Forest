// --- Local variables ---
var hornZones = [getZone(42), getZone(84), getZone(109), getZone(118), getZone(158), getZone(136), getZone(29)];
var yggdrasilZone = getZone(101);
var zonesToCapture = 7; // number of zones to capture for victory
var capturedHorns = 0;

// --- Attack variables
var zoneAttackThreshold = 3; // starting with this many zones, wolfs begin their attack
var currentWave = 0;
var waveSpeed = 120;
var enemyUnits = [];

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
		// forbid players to colonize Yggdrasil
		currentPlayer.allowColonize(yggdrasilZone, false);
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

		var targetPlayer = getPlayerWithMostZones();

		// only attack if minimum zones reached
		if (targetPlayer.zones.length >= zoneAttackThreshold) {
			updateEnemiesAndSpawnNew(targetPlayer.zones.length);

			// attack player with most zones
			var args : Array<Dynamic> = [];
			args.push(targetPlayer.name + " has the largest territory, the forrest wants it back!");
			invokeAll("notifyMessage", args);

			// launch attack
			launchAttackPlayer(enemyUnits, targetPlayer);
		}
	}
}


function getPlayerWithMostZones() : Player {
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

	return playerWithMostZones;
}


function updateEnemiesAndSpawnNew(enemyZones : Int) {
	// spawn wolfes
	var amount = max(1, enemyZones * 2 - 5); // attack with at least one unit
	enemyUnits = enemyUnits.concat(yggdrasilZone.addUnit(Unit.WhiteWolf, amount));

	// spawn valkyries
	if (capturedHorns >= 4) {
		var normalized = capturedHorns - 3;
		var amount = min(6, normalized * normalized); // attack with at most 6 units
		enemyUnits = enemyUnits.concat(yggdrasilZone.addUnit(Unit.Valkyrie, amount));
	}

	// clean enemyUnits array of dead units (we need to do this here, since haxe is to stupid to know the type of unit otherwise)
	var aliveUnits = [];
	for (unit in enemyUnits) {
		if (unit.isRemoved() == false) {
			aliveUnits.push(unit);
		}
	}
	enemyUnits = aliveUnits;
}

// --- Player specific functions

function notifyMessage(message: String) {
	me().genericNotify(message);
}