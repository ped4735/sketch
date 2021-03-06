//@ ugl.bgcolor = 0xFFFFFF

import flash.geom.Point;
import vault.ds.Tuple;

import vault.algo.Voronoi;
import vault.algo.Voronoi.Edge;

class C {
  static public var white = 0xFFFFFF;
  static public var black = 0x1C140D;
  static public var green = 0xCBE86B;
  static public var lightgreen = 0xe2e9af;
  static public var purple = 0x936be8; // 0xdf9bea; // 0xF2E9E1;
  static public var red = 0xd7364e;
  static public var blue = 0x6baee8;
  static public var orange = 0xe8996b;
  static public var clear = 0xF2E9E1;

  static public function line(l: Int) {
    return switch(l) {
      case 0: C.green;
      case 1: C.purple;
      case 2: C.blue;
      case 3: C.orange;
      default: C.clear;
    };
  }
}

class LD29 extends Micro {
  public var score = 0.0;
  var displayScore: Scorer;
  static public function main() {
    Micro.baseColor = 0x000000;
    new Sound("reach").coin(82);
    new Sound("timeup").vol(0.1).explosion(4073);
    new Sound("explosion").explosion(4005);
    new LD29("You are a metro car", "a LD29 game by Fernando Serboncini");
  }

  var mission: Mission;
  public var enemies = 0;

  override public function begin() {
    new Grid();
    new Train(Game.one("Station"));
    displayScore = new Scorer();

    Message.chain(["you are a metro car" ]);

    new Timer().delay(5).run(function() {
      mission = new Mission();
      return true;
    });

    enemies = 0;
    score = 0.0;
  }

  override public function final() {
  }

  override public function end() {
    var p: Train = Game.one("Train");
    new Sound("explosion").play();
      new Particle().xy(p.pos.x, p.pos.y).color(C.green).spread(10)
        .count(200).size(6).speed(30, 70).duration(1.0);
    p.remove();
    new Score(score, true);
    Game.shake(1.0);
  }

  public function newMission() {
    new Timer().delay(10).run(function() {
      mission = new Mission();
      return true;
      });
  }

  public function randomStation(): Station {
    var s: Station = null;
    var i = 1;
    for (e in Game.get("Station")) {
      if (e.pos.x >= 0 && e.pos.x < 480 && e.pos.y >= 0 && e.pos.y < 480) continue;
      if (s == null || Math.random() < 1.0/i) {
        s = cast e;
      }
      i++;
    }
    return s;
  }

  function addEnemy() {
    new Enemy(randomStation());
    enemies++;
  }

  override public function update() {
    var camera = new Vec2(0, 0);

    var t = Game.one("Train");
    camera.x = t.pos.x - 240;
    camera.y = t.pos.y - 240;

    for (c in [ "Grid", "Station", "Train", "Enemy" ] ) {
      for (e in Game.get(c)) {
        e.pos.x -= camera.x;
        e.pos.y -= camera.y;
      }
    }

    var targetEnemies = 5*Math.sqrt(Game.totalTime);

    while (enemies < targetEnemies) {
      addEnemy();
    }

    score += Game.time*Math.sqrt(enemies)/50.0;

    displayScore.score = score;
    new Score(score, false);
  }
}

class Scorer extends Entity {
  static var layer = 400;
  public var score = 0.0;
  override public function begin() {
    pos.x = 10;
    pos.y = 10;
    alignment = TOPLEFT;
  }
  override public function update() {
    gfx.clear();
    var s = Std.int(score);
    gfx.cache(s).fill(C.black).rect(0, 0, 80, 30).text(40, 15, "" + s, C.white, 2);
  }
}

class Mission extends Entity {
  static var layer = 499;

  var target: TargetStation = null;
  var target_station: Station;
  var time = 0.0;
  var end = -1.0;
  var combo = 0;
  var msg = "";

  function getNext(): Float {
    if (target != null) target.remove();
    target_station = Game.scene.randomStation();
    target = new TargetStation(target_station);
    var dist:Vec2 = Game.one("Train").pos.distance(target_station.pos);
    return dist.length;
  }

  override public function begin() {
    pos.x = 240;
    pos.y = 500;
    time = getNext()/20;
    msg = "Get to the station!";
  }

  function finish() {
    target.remove();
    if (end < 0) {
      new Sound("timeup").play();
      end = 3.0;
      Game.scene.mission = null;
      if (combo <= 1) {
        msg = "nope";
      } else {
        msg = "Final combo x" + combo + "!";
      }
    }
  }

  public function station(s: Station) {
    if (s == target_station) {
      new Sound("reach").play();
      Game.shake(0.1);
      combo++;
      Game.scene.score += 10*combo*Math.sqrt(Game.scene.enemies)/5;
      if (combo == 1) {
        msg = "Go to the next one!";
      } else {
        msg = "Combo x" + combo + "! Next!";
      }
      time += getNext()/(20 + 30*combo);
    }
  }

  override public function update() {
    gfx.clear().fill(C.red).rect(0, 0, 270, 30).text(120, 15, msg, C.white, 2);

    if (end >= 0.0) {
      end -= Game.time/0.5;
      pos.y = 440 + 60*Ease.cubicOut(1.0 - Math.min(1.0, end));
      if (end <= 0.0) {
        remove();
        Game.scene.newMission();
        return;
      }
      ticks -= Game.time;
    }
    if (ticks < 0.5) {
      pos.y = 500 - 60*Ease.cubicIn(ticks/0.5);
    }

    var target = 2*Math.PI - 2*Math.PI*(time - ticks)/time;
    if (target >= 2*Math.PI) {
      finish();
      return;
    }
    gfx.fill(C.white);
    gfx.mt(255, 15);
    gfx.lt(255 + 10, 15);
    for (i in 0...16) {
      var ang = Math.max(target, 2*Math.PI - 2*Math.PI*i/16.0);
      var x = 255 + 10*Math.cos(ang);
      var y = 15 - 10*Math.sin(ang);
      gfx.lt(x, y);
    }
    gfx.lt(255, 15);
  }
}

class TargetStation extends Entity {
  static var layer = 450;
  var target: Station;

  override public function begin() {
    target = args[0];
  }

  override public function update() {
    pos.x = target.pos.x;
    pos.y = target.pos.y;

    if (pos.x < 0 || pos.y < 0 || pos.x >= 480 || pos.y >= 480) {
      gfx.clear().fill(C.red).mt(0, 0).lt(15, 7.5).lt(0, 15).lt(0, 0);

      pos.x = Math.max(10, Math.min(470, pos.x));
      pos.y = Math.max(10, Math.min(470, pos.y));

      var v = pos.distance(new Vec2(240, 240));
      angle = v.angle;

    } else {
      angle = 0.0;
      gfx.clear().fill(C.red).circle(8, 8, 8)
       .fill(C.white).circle(8, 8, 6)
       .fill(C.red).circle(8, 8, 4);
    }

  }
}

class Grid extends Entity {
  static var layer = 10;
  var edges: Array<Edge>;

  override public function begin() {
    alignment = TOPLEFT;
    createStations();
  }

  function createStations() {
    var points = new Array<Point>();

    var DIM = 480*4;
    pos.x = pos.y = -DIM/2.0;

    var attemps = 0;
    while (attemps < 3000 && points.length < 500) {
      attemps++;
      var p = new Point(Std.int(DIM*Math.random()), Std.int(DIM*Math.random()));

      var mindist:Float = DIM*DIM;
      for (s in points) {
        var d = (s.x - p.x)*(s.x - p.x) + (s.y - p.y)*(s.y - p.y);
        mindist = Math.min(mindist, Math.sqrt(d));
      }
      if (mindist < 75) continue;
      points.push(p);
    }
    // trace(attemps + ", " + points.length);

    var vor = new Voronoi();
    var diagram = vor.compute(points, new Rectangle(0, 0, DIM, DIM));

    var stations = new Map<String, Station>();
    for (p in points) {
      stations[p.x + ":" + p.y] = new Station(p.x + pos.x, p.y + pos.y);
    }

    edges = diagram.edges;
    for (e in diagram.edges) {
      if (e.lPoint == null || e.rPoint == null) continue;
      var left = stations.get(e.lPoint.x + ":" + e.lPoint.y);
      var right = stations.get(e.rPoint.x + ":" + e.rPoint.y);
      left.conn.push(right);
      right.conn.push(left);
    }

    for (e in Game.get("Station")) {
      var s: Station = cast e;
      s.conn.sort(function(a, b) {
        var ang_a = a.pos.distance(s.pos).angle;
        var ang_b = b.pos.distance(s.pos).angle;
        if (ang_a < ang_b) {
          return -1;
        } else if (ang_a > ang_b) {
          return 1;
        }
        return 0;
      });
    }

    drawTunnels();
  }

  function drawTunnels() {
    gfx.clear();

    var i = 0;
    for (e in edges) {
      if (e.lPoint == null || e.rPoint == null) continue;
      gfx.line(6, C.clear)
        .mt(e.lPoint.x, e.lPoint.y).lt(e.rPoint.x, e.rPoint.y);
    }
  }

  override public function update() {
  }
}

class Station extends Entity {
  static var TYPES = 3;
  static var layer = 15;
  public var conn: Array<Station>;

  override public function begin() {
    pos.x = args[0];
    pos.y = args[1];
    conn = new Array<Station>();

    gfx.fill(C.black).circle(8, 8, 8)
       .fill(C.white).circle(8, 8, 6)
       .fill(C.black).circle(8, 8, 4);
  }
}

class Selection extends Entity {
  static var layer = 14;
  public var from: Station;
  public var to: Station;
  public var color: Int;

  override public function begin() {
    from = args[0];
    to = args[1];
    color = args[2];

    alignment = TOPLEFT;
    pos.x = pos.y = 0;
  }

  override public function update() {
    gfx.clear().line(8, color).mt(from.pos.x, from.pos.y).lt(to.pos.x, to.pos.y);
  }
}

class Train extends Entity {
  static var layer = 25;
  var from: Station;
  var to: Station;
  public var current: Selection;
  var head: Station;
  var path: List<Selection>;
  var selection: Int;
  var sel: Selection;
  var sndStation: Sound;
  var sndSwitch: Sound;

  override public function begin() {
    from = args[0];
    var s = Std.int(from.conn.length*Math.random());
    head = to = from.conn[s];
    pos.x = to.pos.x;
    pos.y = to.pos.y;
    angle = to.pos.distance(from.pos).angle;
    current = new Selection(from, to, C.lightgreen);
    sel = new Selection(to, to.conn[0], C.lightgreen);
    path = new List<Selection>();
    selectPush();
    gfx.fill(C.green).rect(0, 0, 34, 16);
    addHitBox(Rect(0, 0, 34, 16));
    sndStation = new Sound("station").vol(0.15).coin(112);
    sndSwitch = new Sound("switch").hit(764);
  }

  function select(s: Int) {
    selection = (head.conn.length + s) % head.conn.length;
    sel.remove();
    sel = new Selection(head, head.conn[selection], C.purple);
  }

  function selectPush() {
    var c2 = new Selection(sel.from, sel.to, C.lightgreen);
    path.add(c2);
    head = c2.to;
    var last = path.last();
    var cur = last.to.pos.distance(last.from.pos).angle;
    selection = 0;
    var ang = 100.0;
    for (i in 0...last.to.conn.length) {
      var an = Math.abs(
        EMath.angledistance(last.to.conn[i].pos.distance(last.to.pos).angle, cur));
      if (an < ang) {
        ang = an;
        selection = i;
      }
    }
    select(selection);
  }

  static var TURNSPEED = 2.0;
  static var ACCSPEED = 200.0;

  override public function update() {
    var d = to.pos.distance(pos);
    var da = EMath.angledistance(d.angle, angle);
    if (da > 0) da = Math.min(da, Math.PI*TURNSPEED*Game.time);
    else if (da < 0) da = -Math.min(-da, Math.PI*TURNSPEED*Game.time);

    angle += da;

    var acc = 0.0;
    if (Game.key.up) {
      acc = ACCSPEED;
    }
    if (Game.key.down) {
      acc = -ACCSPEED/2.0;
    }

    if (Math.abs(da) < Math.PI/64*Game.time) {
      var fulllength = d.length;

      if (acc > 0) {
        d.length = Math.min(fulllength, acc*Game.time);
        pos.add(d);
      } else if (acc < 0) {
        var back = pos.distance(from.pos);
        d.normalize();
        var backlength = Math.max(0, d.dot(back));
        d.length = Math.min(backlength, -acc*Game.time);
        pos.sub(d);
      }

      if (fulllength <= acc*Game.time) {

        sndStation.play();
        if (Game.scene.mission != null) {
          Game.scene.mission.station(to);
        }
        if (path.length == 0) {
          selectPush();
        }
        if (path.length > 0) {
          current.remove();
          current = path.pop();
          from = to;
          to = current.to;
        }
      }
    }

    if (Game.key.left_pressed) {
      sndSwitch.play();
      select(selection - 1);
    }
    if (Game.key.right_pressed) {
      sndSwitch.play();
     select(selection + 1);
   }
  }
}

class Enemy extends Entity {
  static var layer = 23;
  var from: Station;
  var to: Station;

  override public function begin() {
    from = args[0];
    var s = Std.int(from.conn.length*Math.random());
    to = from.conn[s];
    pos.x = from.pos.x;
    pos.y = from.pos.y;
    angle = to.pos.distance(from.pos).angle;
    gfx.clear();
    gfx.fill(C.black).line(2, C.black).rect(0, 0, 34, 16);

    addHitBox(Rect(0, 0, 34, 16));
  }
  static var TURNSPEED = 1.5;
  static var ACCSPEED = 80.0;

  override public function update() {
    var d = to.pos.distance(pos);
    var da = EMath.angledistance(d.angle, angle);
    if (da > 0) da = Math.min(da, Math.PI*TURNSPEED*Game.time);
    else if (da < 0) da = -Math.min(-da, Math.PI*TURNSPEED*Game.time);

    angle += da;

    if (Math.abs(da) < Math.PI/64*Game.time) {
      var fulllength = d.length;
      d.length = Math.min(fulllength, ACCSPEED*Game.time);
      pos.add(d);
      if (fulllength <= ACCSPEED*Game.time) {
        var old = from;
        from = to;
        to = null;
        var t = 1;
        for (s in from.conn) {
          if (to == null || to == old || Math.random() < 1.0/t) {
            to = s;
          }
          t += 1;
        }
      }
    }

    var p: Train = Game.one("Train");
    if (p != null && hit(p)) {
      Game.scene.endGame();
    }
  }
}

class Message extends Entity {
  static var layer = 500;
  var next: Void -> Void;

  static public function chain(msgs: Array<String>) {
    var f = function() {};

    while (msgs.length > 1) {
      var m = msgs.pop();
      var oldf = f;
      f = function() { new Message(m, oldf); }
    }
    new Message(msgs.pop(), f);
  }

  override public function begin() {
    next = args[1];
    gfx.fill(C.black).rect(0, 0, 480, 30).text(240, 15, args[0], C.white, 2);
    pos.x = -240;
    pos.y = 440;
  }

  override public function update() {
    pos.x = -240 + Math.min(1.0, Ease.quadIn(ticks/0.75))*480;

    if (ticks >= 3.0) {
      pos.x = 240 + Math.min(1.0, Ease.quadIn((ticks - 3.0)/0.75))*480;
    }
    if (ticks >= 4.0) {
      remove();
      next();
    }
  }
}
