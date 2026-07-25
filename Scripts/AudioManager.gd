class_name AudioManager extends Control

var bgmPlayer : AudioStreamPlayer;

var allBgmPlayers : Dictionary = {}
var loopBgmForPlayer : Dictionary = {}
var tweenForPlayer : Dictionary = {}

var sfxPlayersForKey : Dictionary = {} # each player has its own key, so it can only play once

var initialized: bool = false;

static var addedToTree : bool = false;

static var _instance : AudioManager = null
static func ins() -> AudioManager:
    if _instance == null:
        _instance = AudioManager.new()
        _instance.process_mode = Node.PROCESS_MODE_ALWAYS
    return _instance
    
func addNodeToTree(tree : SceneTree) -> void:
    # TODO: causes errors when you relaunch the room
    if self.get_parent_control() == null:
        tree.root.add_child(self)

func makeNewBgmPlayer(key : String) -> AudioStreamPlayer:
    if allBgmPlayers.get(key):
        return allBgmPlayers[key]
        
    var player : AudioStreamPlayer = AudioStreamPlayer.new()
    self.add_child(player)
    player.finished.connect(bgm_finished.bind(player))
    allBgmPlayers[key] = player
    
    if player in loopBgmForPlayer:
        loopBgmForPlayer.erase(player)
    return player
    
# Called when the node enters the scene tree for the first time.
func _init() -> void:
    # one-time progmatic bus setup
    AudioServer.add_bus()
    AudioServer.add_bus()
    AudioServer.add_bus()
    AudioServer.set_bus_name(2, "BGM")
    AudioServer.set_bus_name(3, "SFX")
    
    configure_audio_buses()
    
# use this to configure the master levels for each audio type
func configure_audio_buses() -> void:
    var sdm : SaveDataMgr = SaveDataMgr.create_sdm()
    if !sdm:
        return
        
    var bgmSetting : int = sdm.get_music()
    var sfxSetting : int = sdm.get_sound()
    var bgmDb : int = -5 + -2 * (10-bgmSetting)
    var sfxDb : int = -5 + -2 * (10-sfxSetting)
    if bgmSetting == 0:
        bgmDb = -99999
    if sfxSetting == 0:
        sfxDb = -99999
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), bgmDb)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), sfxDb)
    
func remove_tween_for_player(bgmKey : String) -> void:
    if bgmKey in tweenForPlayer:
        var tween : Tween = tweenForPlayer[bgmKey]
        tweenForPlayer.erase(bgmKey)
        if tween.is_valid():
            tween.kill()
    
func stop_all_BGM() -> void:
    for key : String in allBgmPlayers.keys():
        stop_specific_BGM(key)
    # TODO: implement "autostop" for games with just one bgm track
    
func stop_specific_BGM(bgmKey : String) -> void:
    if bgmKey in allBgmPlayers:
        var player : AudioStreamPlayer = allBgmPlayers[bgmKey]
        player.stop()
        if player in loopBgmForPlayer:
            loopBgmForPlayer.erase(player) 
            
func fade_all_BGM() -> void:
    for key : String in allBgmPlayers.keys():
        fade_specific_BGM(key, false)
        
func crossfade_to_BGM(bgmKey : String, firstKey : Resource, loopKey : Resource) -> void: 
    # if this is interrupted you will probably just die
    ensure_initialized()
        
    var player : AudioStreamPlayer = makeNewBgmPlayer(bgmKey)
    if player in loopBgmForPlayer:
        if loopBgmForPlayer[player] == loopKey: # already playing, leave
            return
            
    if len(loopBgmForPlayer.keys()) == 0: # no music?
        play_BGM(bgmKey, firstKey, loopKey)
        return
        
    fade_all_BGM()
    await self.get_tree().create_timer(1.1).timeout 
    play_BGM(bgmKey, firstKey, loopKey)
    
func fade_specific_BGM(bgmKey : String, fadeIn : bool) -> void:
    if bgmKey in allBgmPlayers:
        var player : AudioStreamPlayer = allBgmPlayers[bgmKey]
        
        remove_tween_for_player(bgmKey)
        var tween : Tween = get_tree().create_tween()
        if fadeIn == false:
            tween.tween_property(player, "volume_db", -20, 1)
            tween.tween_callback(stop_specific_BGM.bind(bgmKey))
        else: # fade in, make sure it's quiet
            player.volume_db = -20
            tween.tween_property(player, "volume_db", 0, 1)
            
func fade_specific_SFX(sfxKey : Resource, fadeIn : bool) -> void:
    # TODO: unify SFX/BGM. this currently doesn't like... check for safety if it's tweening
    var player : AudioStreamPlayer = SFX_player_for_key(sfxKey)
        
    var tween : Tween = get_tree().create_tween()
    if fadeIn == false:
        tween.tween_property(player, "volume_db", -80, 2)
    else: # fade in, make sure it's quiet
        player.volume_db = -20
        tween.tween_property(player, "volume_db", 0, 1)
            
func seek_BGM(bgmKey : String, time : float) -> void:
    if bgmKey in allBgmPlayers:
        var player : AudioStreamPlayer = allBgmPlayers[bgmKey]
        if player.playing:
            player.seek(time)
            
func mute_BGM(bgmKey : String, mute : bool) -> void:
    if bgmKey in allBgmPlayers:
        var player : AudioStreamPlayer = allBgmPlayers[bgmKey]
        if player.playing:
            if mute:
                player.volume_db = -80
            else:
                player.volume_db = 0
        
func play_BGM(bgmKey : String, firstKey : Resource, loopKey : Resource) -> void:
    ensure_initialized()
        
    var player : AudioStreamPlayer = makeNewBgmPlayer(bgmKey)
    if player in loopBgmForPlayer:
        if loopBgmForPlayer[player] == loopKey: # already playing, leave
            return
            
    loopBgmForPlayer[player] = loopKey
    
    player.volume_db = 0
    player.stream = firstKey
    player.seek(0)
    (player.stream as AudioStreamOggVorbis).loop = false
    player.bus = "BGM"
    player.play()
    
func bgm_finished(player : AudioStreamPlayer) -> void:
    if player in loopBgmForPlayer:
        player.stream = loopBgmForPlayer[player]
        (player.stream as AudioStreamOggVorbis).loop = true
        player.bus = "BGM"
        player.play()

# TODO: there is weird audio popping sometimes (only on mac?)
func play_SFX(sfxKey : Resource) -> void:
    ensure_initialized()
    
    # note this will only play up to 1 SFX at once, intentionally
    var sfxPlayerThis : AudioStreamPlayer = SFX_player_for_key(sfxKey)
    sfxPlayerThis.stream = sfxKey
    (sfxPlayerThis.stream as AudioStreamOggVorbis).loop = false
    sfxPlayerThis.bus = "SFX"
    sfxPlayerThis.pitch_scale = 1
    sfxPlayerThis.volume_db = 0
    sfxPlayerThis.play()
    
func mute_SFX(sfxKey : Resource, doMute : bool) -> void:
    var sfxPlayerThis : AudioStreamPlayer = SFX_player_for_key(sfxKey)
    if sfxPlayerThis.playing:
        if doMute:
            sfxPlayerThis.volume_db = -80
        else:
            sfxPlayerThis.volume_db = 0
    
func set_SFX_pitch(sfxKey : Resource, pitch : float) -> void:
    var sfxPlayerThis : AudioStreamPlayer = SFX_player_for_key(sfxKey)
    if sfxPlayerThis.playing:
        sfxPlayerThis.pitch_scale = pitch
    
func loop_SFX(sfxKey : Resource) -> void:
    # note this will only play up to 1 SFX at once, intentionally
    var sfxPlayerThis : AudioStreamPlayer = SFX_player_for_key(sfxKey)
    sfxPlayerThis.stream = sfxKey
    (sfxPlayerThis.stream as AudioStreamOggVorbis).loop = true
    sfxPlayerThis.bus = "SFX"
    sfxPlayerThis.volume_db = 0
    sfxPlayerThis.pitch_scale = 1
    sfxPlayerThis.play()
    
func loop_SFX_stop(sfxKey : Resource) -> void:
    # note this will only play up to 1 SFX at once, intentionally
    var sfxPlayerThis : AudioStreamPlayer = SFX_player_for_key(sfxKey)
    sfxPlayerThis.stream = sfxKey
    (sfxPlayerThis.stream as AudioStreamOggVorbis).loop = true
    sfxPlayerThis.bus = "SFX"
    sfxPlayerThis.volume_db = 0
    sfxPlayerThis.stop()
    
func SFX_player_for_key(sfxKey : Resource) -> AudioStreamPlayer:
    if !sfxPlayersForKey.has(sfxKey.resource_path):
        var sfxPlayer : AudioStreamPlayer = AudioStreamPlayer.new()
        self.add_child(sfxPlayer)
        sfxPlayersForKey[sfxKey.resource_path] = sfxPlayer
    
    return sfxPlayersForKey[sfxKey.resource_path]

func ensure_initialized() -> void:
    if !initialized:
        configure_audio_buses()
        initialized = true
