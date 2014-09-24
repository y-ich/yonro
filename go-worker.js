// Generated by CoffeeScript 1.8.0

/*
碁カーネル
中国ルールを採用。ただし自殺手は着手禁止とする。
 */

(function() {
  var BIT_BOARD_SIZE, BLACK, BOARD_SIZE, DEBUG, EMPTY, EvaluationResult, MAX_SCORE, ON_BOARD, OnBoard, WHITE, adjacenciesAt, adjacent, bitsToPositions, bitsToString, boardsToString, borderOf, cache, captured, check, checkHistory, compare, countBits, decomposeToStrings, e, evalUntilDepth, evaluate, interiorOf, onlySuicide, opponentOf, positionToBit, positionsToBits, root, stringOf, _BITS, _i, _j, _k, _len, _len1, _len2, _ref, _ref1, _ref2, _ref3, _ref4;

  Array.prototype.isEqualTo = function(array) {

    /*　配列の要素すべてが等しいか否かを返す。 */
    if (this.length !== array.length) {
      return false;
    }
    return this.every(function(e, i) {
      return e === array[i];
    });
  };

  BOARD_SIZE = 4;

  MAX_SCORE = BOARD_SIZE * BOARD_SIZE - 2;

  EMPTY = 0;

  BLACK = 1;

  WHITE = 2;

  boardsToString = function(history) {
    return history.map(function(e, i) {
      return "#" + i + "\n" + (e.toString());
    }).join('\n');
  };

  opponentOf = function(stone) {

    /* 黒(BLACK)なら白(WHITE)、白(WHITE)なら黒(BLACK)を返す。 */
    switch (stone) {
      case BLACK:
        return WHITE;
      case WHITE:
        return BLACK;
      default:
        throw 'error';
    }
  };

  adjacenciesAt = function(position) {

    /* プライベート */

    /* 隣接する点の座標の配列を返す。 */
    var e, result, x, y, _i, _len, _ref;
    result = [];
    _ref = [[0, -1], [-1, 0], [1, 0], [0, 1]];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      e = _ref[_i];
      x = position[0] + e[0];
      y = position[1] + e[1];
      if ((0 <= x && x < BOARD_SIZE) && (0 <= y && y < BOARD_SIZE)) {
        result.push([x, y]);
      }
    }
    return result;
  };

  root = typeof exports !== "undefined" && exports !== null ? exports : typeof window !== "undefined" && window !== null ? window : {};

  _ref = ['BLACK', 'WHITE', 'EMPTY', 'BOARD_SIZE', 'MAX_SCORE', 'opponentOf', 'adjacenciesAt', 'boardsToString'];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    e = _ref[_i];
    root[e] = eval(e);
  }


  /*
  碁カーネル(ビッとボードバージョン)
  中国ルールを採用。ただし自殺手は着手禁止とする。
   */

  if (typeof exports !== "undefined" && exports !== null) {
    _ref1 = require('./go-common.coffee'), BLACK = _ref1.BLACK, WHITE = _ref1.WHITE, EMPTY = _ref1.EMPTY, MAX_SCORE = _ref1.MAX_SCORE, BOARD_SIZE = _ref1.BOARD_SIZE, MAX_SCORE = _ref1.MAX_SCORE, opponentOf = _ref1.opponentOf, boardsToString = _ref1.boardsToString, compare = _ref1.compare;
  }

  positionToBit = function(position) {

    /*
    positionに相当するbitboardを返す。
    bitboardのフォーマットは四路の場合、
    ....F....F....F....
    でFはフレーム(枠)
     */
    return 1 << (position[0] + position[1] * BIT_BOARD_SIZE);
  };

  BIT_BOARD_SIZE = BOARD_SIZE + 1;

  if (BIT_BOARD_SIZE * BOARD_SIZE > 32) {
    throw "overflow " + (BIT_BOARD_SIZE * BOARD_SIZE);
  }

  _BITS = (function() {
    var result, x, y, _j, _k;
    result = [];
    for (x = _j = 0; 0 <= BOARD_SIZE ? _j < BOARD_SIZE : _j > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_j : --_j) {
      for (y = _k = 0; 0 <= BOARD_SIZE ? _k < BOARD_SIZE : _k > BOARD_SIZE; y = 0 <= BOARD_SIZE ? ++_k : --_k) {
        result.push(positionToBit([x, y]));
      }
    }
    return result;
  })();


  /*
  _BITSは位置を示すビットパターンすべての配列。
   */

  ON_BOARD = (function() {
    var b, result, _j, _len1;
    result = 0;
    for (_j = 0, _len1 = _BITS.length; _j < _len1; _j++) {
      b = _BITS[_j];
      result |= b;
    }
    return result;
  })();


  /*
  ON_BOARDは盤上を取り出す(フレームを落とす)ためのマスク
   */

  countBits = function(x) {

    /* 32bit整数の1の数を返す */
    x -= (x >>> 1) & 0x55555555;
    x = (x & 0x33333333) + ((x >>> 2) & 0x33333333);
    x = (x + (x >>> 4)) & 0x0F0F0F0F;
    x += x >>> 8;
    x += x >>> 16;
    return x & 0x0000003F;
  };

  positionsToBits = function(positions) {

    /* positions配列の位置に1を立てたビットボードを返す。 */
    var bits, _j, _len1;
    bits = 0;
    for (_j = 0, _len1 = positions.length; _j < _len1; _j++) {
      e = positions[_j];
      bits |= positionToBit(e);
    }
    return bits;
  };

  bitsToPositions = function(bitBoard) {

    /* ビットボード上の1の位置の配列を返す。 */
    var position, positions, x, y, _j, _k;
    positions = [];
    for (x = _j = 0; 0 <= BOARD_SIZE ? _j < BOARD_SIZE : _j > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_j : --_j) {
      for (y = _k = 0; 0 <= BOARD_SIZE ? _k < BOARD_SIZE : _k > BOARD_SIZE; y = 0 <= BOARD_SIZE ? ++_k : --_k) {
        position = [x, y];
        if (bitBoard & positionToBit(position)) {
          positions.push(position);
        }
      }
    }
    return positions;
  };

  adjacent = function(bitBoard) {

    /* 呼吸点を返す。 */
    var expanded;
    expanded = bitBoard << BIT_BOARD_SIZE;
    expanded |= bitBoard << 1;
    expanded |= bitBoard >>> 1;
    expanded |= bitBoard >>> BIT_BOARD_SIZE;
    return expanded & (~bitBoard) & ON_BOARD;
  };

  stringOf = function(bitBoard, seed) {

    /* seedを含む連を返す。 */
    var expanded;
    if (!(bitBoard & seed)) {
      return 0;
    }
    while (true) {
      expanded = (seed | (seed << BIT_BOARD_SIZE) | (seed << 1) | (seed >>> 1) | (seed >>> BIT_BOARD_SIZE)) & bitBoard;
      if (expanded === seed) {
        return expanded;
      }
      seed = expanded;
    }
  };

  interiorOf = function(region) {

    /* 領域の内部を返す */
    return region & (region << BIT_BOARD_SIZE) & (region << 1) & (region >>> 1) & (region >>> BIT_BOARD_SIZE);
  };

  borderOf = function(region) {
    return region & ~interiorOf(region);
  };

  captured = function(objective, subjective) {

    /* subjectiveで囲まれたobjectiveの部分を返す。 */
    var breaths, liberty;
    liberty = adjacent(objective) & ~subjective;
    breaths = objective & adjacent(liberty);
    return objective & (~stringOf(objective, breaths));
  };

  decomposeToStrings = function(bitBoard) {

    /* 盤上の石をストリングに分解する。 */
    var bit, result, _j, _len1;
    result = [];
    for (_j = 0, _len1 = _BITS.length; _j < _len1; _j++) {
      bit = _BITS[_j];
      if ((bitBoard & bit) && result.every(function(b) {
        return (b & bit) === 0;
      })) {
        result.push(stringOf(bitBoard, bit));
      }
    }
    return result;
  };

  bitsToString = function(bitBoard) {

    /* bitBoardを文字列にする */
    var str, x, y, _j, _k;
    str = '';
    for (y = _j = 0; 0 <= BOARD_SIZE ? _j < BOARD_SIZE : _j > BOARD_SIZE; y = 0 <= BOARD_SIZE ? ++_j : --_j) {
      for (x = _k = 0; 0 <= BOARD_SIZE ? _k < BOARD_SIZE : _k > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_k : --_k) {
        str += bitBoard & positionToBit([x, y]) ? 'O' : '.';
      }
      if (y !== BOARD_SIZE - 1) {
        str += '\n';
      }
    }
    return str;
  };

  OnBoard = (function() {

    /* 盤上の状態を表すクラス */
    OnBoard.fromString = function(str) {

      /* 盤上の状態を表すX(黒)とO(白)と空点(スペース)と改行で文字列からインスタンスを生成する。 */
      var blacks, line, lines, whites, x, y, _j, _k, _len1;
      blacks = [];
      whites = [];
      lines = str.replace(/(\r?\n)*$/, '').split(/\r?\n/);
      if (lines.length !== BOARD_SIZE) {
        throw 'bad format';
      }
      for (y = _j = 0, _len1 = lines.length; _j < _len1; y = ++_j) {
        line = lines[y];
        if (line.length !== BOARD_SIZE) {
          throw 'bad format';
        }
        for (x = _k = 0; 0 <= BOARD_SIZE ? _k < BOARD_SIZE : _k > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_k : --_k) {
          switch (line.charAt(x)) {
            case 'X':
              blacks.push([x, y]);
              break;
            case 'O':
              whites.push([x, y]);
              break;
            case ' ':
              null;
              break;
            default:
              throw 'bad format';
          }
        }
      }
      return new OnBoard(blacks, whites);
    };

    OnBoard.random = function() {

      /* ランダムな配置の碁盤を返す。 */
      var bitPos, blacks, result, whites, _j, _len1;
      while (true) {
        blacks = 0;
        whites = 0;
        for (_j = 0, _len1 = _BITS.length; _j < _len1; _j++) {
          bitPos = _BITS[_j];
          switch (Math.floor(Math.random() * 3)) {
            case 1:
              blacks |= bitPos;
              break;
            case 2:
              whites |= bitPos;
          }
        }
        result = new OnBoard(blacks, whites);
        if (result.isLegal()) {
          return result;
        }
      }
    };

    function OnBoard(blacks, whites) {

      /* blacks, whitesは黒石/白石のある場所の座標の配列。 */
      if (blacks instanceof Array && whites instanceof Array) {
        this.black = positionsToBits(blacks);
        this.white = positionsToBits(whites);
      } else if (typeof blacks === 'number' && typeof whites === 'number') {
        this.black = blacks;
        this.white = whites;
      } else {
        this.black = 0;
        this.white = 0;
      }
    }

    OnBoard.prototype.isEmptyAt = function(position) {

      /* 座標が空点かどうか。 */
      return this._isEmptyAt(positionToBit(position));
    };

    OnBoard.prototype._isEmptyAt = function(bitPos) {

      /* 座標が空点かどうか。 */
      return !((this.black | this.white) & bitPos);
    };

    OnBoard.prototype.isLegalAt = function(stone, position) {

      /*
      座標が合法着手点かどうか。
      コウ(循環)の着手禁止はチェックしない。循環については手順関連で別途チェックすること
       */
      var board;
      board = this.copy();
      return board.place(stone, position);
    };

    OnBoard.prototype.isLegal = function() {

      /* 盤上の状態が合法がどうか。(ダメ詰まりの石が存在しないこと) */
      return captured(this.black, this.white) === 0 && captured(this.white, this.black) === 0;
    };

    OnBoard.prototype.isEqualTo = function(board) {

      /* 盤上が同じかどうか。 */
      if (typeof board === 'string') {
        board = OnBoard.fromString(board);
      }
      return this.black === board.black && this.white === board.white;
    };

    OnBoard.prototype.stateAt = function(position) {

      /* 座標の状態を返す。 */
      return this._stateAt(positionToBit(position));
    };

    OnBoard.prototype._stateAt = function(bitPos) {
      if (this.black & bitPos) {
        return BLACK;
      } else if (this.white & bitPos) {
        return WHITE;
      } else {
        return EMPTY;
      }
    };

    OnBoard.prototype.numOf = function(stone) {

      /* 盤上の石または空点の数を返す。 */
      return countBits((function() {
        switch (stone) {
          case EMPTY:
            return this._empties();
          case BLACK:
            return this.black;
          case WHITE:
            return this.white;
          default:
            throw 'numOf';
            return 0;
        }
      }).call(this));
    };

    OnBoard.prototype.deployment = function() {

      /*
      現在の配置を返す。
      コンストラクタの逆関数
       */
      return [bitsToPositions(this.black), bitsToPositions(this.white)];
    };

    OnBoard.prototype.score = function() {

      /*
      石の数の差を返す。
      中国ルールを採用。盤上の石の数の差が評価値。
       */
      return countBits(this.black) - countBits(this.white);
    };

    OnBoard.prototype.add = function(stone, position) {

      /*
      石を座標にセットする。
      stateはBLACK, WHITEのいずれか。(本当はEMPTYもOK)
       */
      return this._add(stone, positionToBit(position));
    };

    OnBoard.prototype._add = function(stone, bitPos) {
      switch (stone) {
        case BLACK:
          this.black |= bitPos;
          this.white &= ~bitPos;
          break;
        case WHITE:
          this.white |= bitPos;
          this.black &= ~bitPos;
          break;
        case EMPTY:
          this.black &= ~bitPos;
          this.white &= ~bitPos;
          break;
        default:
          throw 'add: unknown stone type';
      }
    };

    OnBoard.prototype["delete"] = function(position) {

      /* 座標の石をただ取る。 */
      return this._delete(positionToBit(position));
    };

    OnBoard.prototype._delete = function(bitPos) {
      this.black &= ~bitPos;
      return this.white &= ~bitPos;
    };

    OnBoard.prototype.candidates = function(stone) {

      /* stoneの手番で、合法かつ自分の眼ではない座標に打った局面を返す。 */
      var bitPos, board, result, _j, _len1;
      result = [];
      for (_j = 0, _len1 = _BITS.length; _j < _len1; _j++) {
        bitPos = _BITS[_j];
        if (this._whoseEyeAt(bitPos, true) === stone) {
          continue;
        }
        board = this.copy();
        if (board._place(stone, bitPos)) {
          result.push(board);
        }
      }
      return result;
    };

    OnBoard.prototype.stringAt = function(position) {
      return this.stringOf(positionToBit(position));
    };

    OnBoard.prototype.stringOf = function(bitPos) {
      var board;
      board = (function() {
        switch (this._stateAt(bitPos)) {
          case BLACK:
            return this.black;
          case WHITE:
            return this.white;
          default:
            return this._empties();
        }
      }).call(this);
      return stringOf(board, bitPos);
    };

    OnBoard.prototype.stringAndLibertyAt = function(position) {

      /*
      座標の石と接続した同一石の座標の配列とその石の集合のダメの座標の配列を返す。
      接続した石の集団を連(ストリング)と呼ぶ。
       */
      var s;
      s = this.stringAt(position);
      return [s, this._libertyOf(s)];
    };

    OnBoard.prototype._libertyOf = function(string) {
      var opponent;
      opponent = this.black & string ? this.white : this.black;
      return adjacent(string) & ~opponent;
    };

    OnBoard.prototype.numOfLibertiesOf = function(string) {
      return countBits(this._libertyOf(string));
    };

    OnBoard.prototype._empties = function() {
      return ON_BOARD & ~(this.black | this.white);
    };

    OnBoard.prototype.emptyStrings = function() {

      /* 盤上の空点のストリングを返す。 */
      return decomposeToStrings(this._empties());
    };

    OnBoard.prototype.numOfLiberties = function(stone) {
      var lib, opponent, self;
      switch (stone) {
        case BLACK:
          self = this.black;
          opponent = this.white;
          break;
        case WHITE:
          self = this.white;
          opponent = this.black;
      }
      lib = adjacent(self) & ~opponent;
      return countBits(lib);
    };

    OnBoard.prototype.strings = function() {

      /* 盤上のストリングを返す。1つ目の要素が黒のストリング、2つ目の要素が白のストリング。 */
      return [decomposeToStrings(this.black), decomposeToStrings(this.white)];
    };

    OnBoard.prototype.isTouchedBetween = function(a, b) {

      /* ストリングa, bが接触しているかどうか。 */
      return (adjacent(a) | b) !== 0;
    };

    OnBoard.prototype.stringsToContacts = function(strings) {

      /* string(接続した石の集合)の配列からcontact(接続もしくは接触した石の集合)を算出して返す。 */
      var i, j, result, unique, _j, _k, _ref2, _ref3, _ref4;
      result = [];
      for (i = _j = 0, _ref2 = strings.length; 0 <= _ref2 ? _j < _ref2 : _j > _ref2; i = 0 <= _ref2 ? ++_j : --_j) {
        if (result[i] == null) {
          result[i] = [strings[i]];
        }
        for (j = _k = _ref3 = i + 1, _ref4 = strings.length; _ref3 <= _ref4 ? _k < _ref4 : _k > _ref4; j = _ref3 <= _ref4 ? ++_k : --_k) {
          if (this.isTouchedBetween(strings[i], strings[j])) {
            result[i].push(strings[j]);
            result[j] = result[i];
          }
        }
      }
      unique = function(array) {
        var _l, _len1;
        result = [];
        for (_l = 0, _len1 = array.length; _l < _len1; _l++) {
          e = array[_l];
          if (result.indexOf(e) < 0) {
            result.push(e);
          }
        }
        return result;
      };
      return unique(result);
    };

    OnBoard.prototype.whoseEyeAt = function(position, genuine) {
      if (genuine == null) {
        genuine = false;
      }
      return this._whoseEyeAt(positionToBit(position), genuine);
    };

    OnBoard.prototype._whoseEyeAt = function(bitPos, genuine, checkings) {
      var adj, bitBoard, emptyString, gds, stone, strings;
      if (genuine == null) {
        genuine = false;
      }
      if (checkings == null) {
        checkings = 0;
      }

      /*
      座標が眼かどうか調べ、眼ならばどちらの眼かを返し、眼でないならnullを返す。
      眼の定義は、その座標が同一石で囲まれていて、囲んでいる石がその座標以外のダメを詰められないこと。
      checkingsは再帰用引数
      石をかこっている時、2目以上の空点の時、眼と判定しないので改良が必要。
       */
      if (!this._isEmptyAt(bitPos)) {
        return null;
      }
      emptyString = this.stringOf(bitPos);
      if (countBits(emptyString) >= 8) {
        return null;
      }
      adj = adjacent(emptyString);
      if (adj === 0) {
        stone = null;
      } else if ((adj & this.black) === adj) {
        stone = BLACK;
        bitBoard = this.black;
      } else if ((adj & this.white) === adj) {
        stone = WHITE;
        bitBoard = this.white;
      } else if (!genuine) {
        strings = decomposeToStrings(stringOf(this.white, adj & this.white));
        if (strings.length === 1 && countBits(adjacent(strings[0]) & ~this.black) === 1 && decomposeToStrings(stringOf(this.black, adj & this.black)).map((function(_this) {
          return function(e) {
            return countBits(_this._libertyOf(e));
          };
        })(this)).every(function(e) {
          return e > 1;
        })) {
          return BLACK;
        }
        strings = decomposeToStrings(stringOf(this.black, adj & this.black));
        if (strings.length === 1 && countBits(adjacent(strings[0]) & ~this.white) === 1 && decomposeToStrings(stringOf(this.white, adj & this.white)).map((function(_this) {
          return function(e) {
            return countBits(_this._libertyOf(e));
          };
        })(this)).every(function(e) {
          return e > 1;
        })) {
          return WHITE;
        }
        stone = null;
        bitBoard = null;
      } else {
        stone = null;
        bitBoard = null;
      }
      if (stone == null) {
        return null;
      }
      gds = decomposeToStrings(stringOf(bitBoard, adj));
      if (gds.length === 1 || (gds.every((function(_this) {
        return function(gd) {
          var b, liberty, _j, _len1;
          liberty = adjacent(gd) & ~bitPos;
          if (liberty & checkings) {
            return true;
          }
          for (_j = 0, _len1 = _BITS.length; _j < _len1; _j++) {
            b = _BITS[_j];
            if ((b & liberty) && _this._whoseEyeAt(b, genuine, checkings | bitPos) === stone) {
              return true;
            }
          }
          return false;
        };
      })(this)))) {
        return stone;
      } else {
        return null;
      }
    };

    OnBoard.prototype.eyes = function() {

      /* 眼の座標を返す。１つ目は黒の眼、２つ目は白の眼。 */
      var b, result, _j, _len1, _ref2;
      result = [[], []];
      _ref2 = this.emptyStrings();
      for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
        b = _ref2[_j];
        switch (this._whoseEyeAt(b)) {
          case BLACK:
            result[0].push(b);
            break;
          case WHITE:
            result[1].push(b);
        }
      }
      return result;
    };

    OnBoard.prototype.enclosedRegionsOf = function(stone) {
      var opponent, regions, self;
      switch (stone) {
        case BLACK:
          self = this.black;
          opponent = this.white;
          break;
        case WHITE:
          self = this.white;
          opponent = this.black;
      }
      regions = decomposeToStrings(~self & ON_BOARD);
      return regions.filter(function(r) {
        var i;
        i = interiorOf(r);
        return (i & opponent) === i;
      });
    };

    OnBoard.prototype.atari = function() {
      return bitsToPositions(this._atari());
    };

    OnBoard.prototype._atari = function() {
      var result, s, strings, _j, _len1;
      result = 0;
      strings = [].concat.apply([], this.strings());
      for (_j = 0, _len1 = strings.length; _j < _len1; _j++) {
        s = strings[_j];
        if (this.numOfLibertiesOf(s) === 1) {
          result |= s;
        }
      }
      return result;
    };

    OnBoard.prototype.copy = function() {
      return new OnBoard(this.black, this.white);
    };

    OnBoard.prototype.captureBy = function(stone) {

      /* 相手の石を取り上げて、取り上げた石のビットボードを返す。 */
      var captives;
      switch (stone) {
        case BLACK:
          captives = captured(this.white, this.black);
          this.white &= ~captives;
          break;
        case WHITE:
          captives = captured(this.black, this.white);
          this.black &= ~captives;
      }
      return captives;
    };

    OnBoard.prototype.place = function(stone, position) {

      /*
      石を座標に着手する。
      着手候補を減らす便宜上、自殺手は着手禁止とする。(中国ルールからの逸脱)
      着手が成立したらtrue。着手禁止の場合false。
      循環手か否かは未チェック。
       */
      if (position == null) {
        return true;
      }
      return this._place(stone, positionToBit(position));
    };

    OnBoard.prototype._place = function(stone, bitPos) {
      if (!this._isEmptyAt(bitPos)) {
        return false;
      }
      this._add(stone, bitPos);
      this.captureBy(stone);
      if (this.isLegal()) {
        return true;
      } else {
        this._delete(bitPos);
        return false;
      }
    };

    OnBoard.prototype.toString = function() {
      var str, x, y, _j, _k;
      str = '';
      for (y = _j = 0; 0 <= BOARD_SIZE ? _j < BOARD_SIZE : _j > BOARD_SIZE; y = 0 <= BOARD_SIZE ? ++_j : --_j) {
        for (x = _k = 0; 0 <= BOARD_SIZE ? _k < BOARD_SIZE : _k > BOARD_SIZE; x = 0 <= BOARD_SIZE ? ++_k : --_k) {
          str += (function() {
            switch (this.stateAt([x, y])) {
              case BLACK:
                return 'X';
              case WHITE:
                return 'O';
              default:
                return ' ';
            }
          }).call(this);
        }
        if (y !== BOARD_SIZE - 1) {
          str += '\n';
        }
      }
      return str;
    };

    return OnBoard;

  })();

  root = typeof exports !== "undefined" && exports !== null ? exports : typeof window !== "undefined" && window !== null ? window : {};

  root.OnBoard = OnBoard;

  if (typeof exports !== "undefined" && exports !== null) {
    _ref2 = ['countBits', 'positionToBit', 'positionsToBits', 'bitsToPositions', 'adjacent', 'stringOf', 'captured', 'decomposeToStrings', 'boardsToString', 'compare', 'bitsToString'];
    for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
      e = _ref2[_j];
      if (typeof exports !== "undefined" && exports !== null) {
        root[e] = eval(e);
      }
    }
  }


  /*
  局面評価
  中国ルールを採用。ただし自殺手は着手禁止とする。
   */

  if (typeof exports !== "undefined" && exports !== null) {
    _ref3 = require('./go-common.coffee'), BLACK = _ref3.BLACK, WHITE = _ref3.WHITE, EMPTY = _ref3.EMPTY, MAX_SCORE = _ref3.MAX_SCORE, opponentOf = _ref3.opponentOf, boardsToString = _ref3.boardsToString;
  }

  DEBUG = false;

  check = function(next, board) {
    return next === BLACK && board.isEqualTo(' X  \nX X \nXXOO\n OX ');
  };

  cache = {
    black: [],
    white: [],
    clear: function() {
      this.black = [];
      return this.white = [];
    },
    add: function(next, board, result) {
      var array;
      array = (function() {
        switch (next) {
          case BLACK:
            return this.black;
          case WHITE:
            return this.white;
        }
      }).call(this);
      array.push({
        board: board,
        result: result
      });
    },
    query: function(next, board) {
      var array, index, _k, _len2;
      array = (function() {
        switch (next) {
          case BLACK:
            return this.black;
          case WHITE:
            return this.white;
        }
      }).call(this);
      for (_k = 0, _len2 = array.length; _k < _len2; _k++) {
        e = array[_k];
        if (!(e.board.isEqualTo(board))) {
          continue;
        }
        index = e.result.history.indexOf(e.board);
        return new EvaluationResult(e.result.value, e.result.history.slice(index + 1));
      }
      return null;
    }
  };

  checkHistory = function(history) {
    var historyStrings;
    historyStrings = [' XOO\nXO O\nXXOO\n   O', ' XOO\nXO O\nXXOO\n O O', ' XOO\nX XO\nXXOO\n O O', ' XOO\nX XO\nXXOO\nOO O', ' XOO\nXXXO\nXXOO\nOO O', 'O OO\n   O\n  OO\nOO O', 'O OO\n X O\n  OO\nOO O', 'OOOO\n X O\n  OO\nOO O', 'OOOO\n X O\n XOO\nOO O', 'OOOO\nOX O\n XOO\nOO O', 'OOOO\nOX O\nXXOO\nOO O', 'OOOO\nOX O\nXXOO\nOOOO', '    \n XX \nXX  \n    ', '    \n XX \nXX  \n   O'];
    return history.every(function(e, i) {
      return e.isEqualTo(historyStrings[i]);
    });
  };

  evaluate = function(history, next) {
    var depth, result, _k;
    cache.clear();
    for (depth = _k = 2; _k <= 30; depth = _k += 1) {
      if (DEBUG) {
        console.log("depth: " + depth);
      }
      result = evalUntilDepth(history, next, depth);
      if (DEBUG) {
        console.log(result.toString());
      }
      if (!isNaN(result.value)) {
        return result;
      }
    }
    return result;
  };

  compare = function(a, b, stone) {

    /*
    探索のための優先順位を決める局面比較関数。
    a, bは比較する局面。stoneの立場で比較し、結果を整数値で返す。
    
    0. 相手の石が0
    1. 自分の眼の数に差があればそれを返す。(眼形が多い手を優先する)
    2. スコアに差があればそれを返す。(石を取った手を優先する)
    3. 自分のダメの数と相手のダメの数の差に差があればそれを返す。(攻め合いに有効な手を優先する)
    4. 自分の連(string)の数に差があればそれにマイナスを掛けた値を返す。(つながる手を優先する)
    5. 自分のつながり(contact)の数に差があればそれにマイナスを掛けた値を返す。(つながる手を優先する)
     */
    var aBlack, aWhite, bBlack, bWhite, candidates, dame, diff, opponent, score, strings, _ref4, _ref5;
    opponent = opponentOf(stone);
    candidates = -a.candidates(opponent).length + b.candidates(opponent).length;
    if (candidates !== 0) {
      return candidates;
    }
    _ref4 = a.strings(), aBlack = _ref4[0], aWhite = _ref4[1];
    _ref5 = b.strings(), bBlack = _ref5[0], bWhite = _ref5[1];
    switch (stone) {
      case BLACK:
        dame = (a.numOfLiberties(BLACK) - a.numOfLiberties(WHITE)) - (b.numOfLiberties(BLACK) - b.numOfLiberties(WHITE));
        if (dame !== 0) {
          return dame;
        }
        strings = bBlack.length - aBlack.length;
        if (strings !== 0) {
          return strings;
        }
        aBlack = a.stringsToContacts(aBlack);
        bBlack = b.stringsToContacts(bBlack);
        diff = bBlack.length - aBlack.length;
        if (diff !== 0) {
          return diff;
        }
        score = a.score() - b.score();
        return score;
      case WHITE:
        dame = (a.numOfLiberties(WHITE) - a.numOfLiberties(BLACK)) - (b.numOfLiberties(WHITE) - b.numOfLiberties(BLACK));
        if (dame !== 0) {
          return dame;
        }
        strings = bWhite.length - aWhite.length;
        if (strings !== 0) {
          return strings;
        }
        aWhite = a.stringsToContacts(aWhite);
        bWhite = b.stringsToContacts(bWhite);
        diff = bWhite.length - aWhite.length;
        if (diff !== 0) {
          return diff;
        }
        score = b.score() - a.score();
        return score;
    }
  };

  onlySuicide = function(nodes, next, board) {
    var blacks, strings, suicides, whites, _ref4;
    _ref4 = board.strings(), blacks = _ref4[0], whites = _ref4[1];
    strings = (function() {
      switch (next) {
        case BLACK:
          return blacks;
        case WHITE:
          return whites;
      }
    })();
    suicides = nodes.filter(function(b) {
      return strings.some(function(e) {
        return board.numOfLibertiesOf(e) > 1 && b.numOfLibertiesOf(b.stringOf(e)) === 1;
      });
    });
    return suicides.length === nodes.length;
  };

  EvaluationResult = (function() {
    function EvaluationResult(value, history) {
      this.value = value;
      this.history = history;
    }

    EvaluationResult.prototype.copy = function() {
      return new EvaluationResult(this.value, this.history);
    };

    EvaluationResult.prototype.toString = function() {
      return ("value: " + this.value + "\n") + 'history:\n' + boardsToString(this.history);
    };

    return EvaluationResult;

  })();

  evalUntilDepth = function(history, next, depth, alpha, beta) {
    var b, board, c, candidates, empties, eyes, flag, i, nan, nodes, notPossibleToIterate, opponent, parity, result, updated, _k, _l, _len2, _len3;
    if (alpha == null) {
      alpha = new EvaluationResult(-Infinity, []);
    }
    if (beta == null) {
      beta = new EvaluationResult(Infinity, []);
    }

    /*
    historyはOnBoardインスタンスの配列
    historyの最終局面の評価値と評価値に至る手順を返す。
    nextは次の手番。
    depthは最大深度。反復進化パラメータ
    alpha, betaはαβ枝狩りパラメータ
    外部関数compareが肝。
     */
    board = history[history.length - 1];
    if (DEBUG && check(next, board)) {
      flag = true;
      console.log("depth" + depth + ", alpha" + alpha.value + ", beta" + beta.value);
    }
    if ((board === history[history.length - 2]) && (board === history[history.length - 3])) {
      return new EvaluationResult(board.score(), history);
    }
    eyes = board.eyes();
    empties = board.numOf(EMPTY);
    if (eyes[0].length === empties || (board.numOf(WHITE) === 0 && eyes[0].length > 0)) {
      return new EvaluationResult(MAX_SCORE, history);
    }
    if (eyes[1].length === empties || (board.numOf(BLACK) === 0 && eyes[1].length > 0)) {
      return new EvaluationResult(-MAX_SCORE, history);
    }
    if (depth <= 0) {
      return new EvaluationResult(NaN, history);
    }
    opponent = opponentOf(next);
    candidates = board.candidates(next);
    parity = history.length % 2;
    nodes = candidates.filter(function(b) {
      return history.filter(function(e, i) {
        return (i % 2) === parity;
      }).every(function(e) {
        return !b.isEqualTo(e);
      });
    });
    notPossibleToIterate = candidates.length === nodes.length;
    c = cache.query(next, board);
    if ((c != null) && notPossibleToIterate) {
      return new EvaluationResult(c.value, history.concat(c.history));
    }
    nodes.sort(function(a, b) {
      return -compare(a, b, next);
    });
    if (onlySuicide(nodes, next, board)) {
      nodes.push(board);
    }
    if (flag) {
      console.log('nodes');
      console.log(boardsToString(nodes));
    }
    nan = null;
    updated = false;
    switch (next) {
      case BLACK:
        for (i = _k = 0, _len2 = nodes.length; _k < _len2; i = ++_k) {
          b = nodes[i];
          result = evalUntilDepth(history.concat(b), opponent, depth - 1, alpha, beta);
          if (flag) {
            console.log("b" + i + " depth" + depth);
            console.log("alpha" + alpha.value + ", beta" + beta.value);
            console.log(b.toString());
            console.log(result.toString());
            console.log(result.value === alpha.value);
          }
          if ((result.value > alpha.value) || (result.value === alpha.value && result.history.length < alpha.history.length)) {
            alpha = result;
          } else if (isNaN(result.value)) {
            if (nan == null) {
              nan = result;
            }
          }
          if (alpha.value >= beta.value) {
            return beta;
          }
        }
        if ((nan != null) && alpha.value < MAX_SCORE) {
          return nan;
        }
        if (notPossibleToIterate && history.every(function(e, i) {
          return e === alpha.history[i];
        })) {
          cache.add(next, board, alpha);
        }
        if (alpha.value === -Infinity) {
          return nan;
        } else {
          return alpha;
        }
      case WHITE:
        for (i = _l = 0, _len3 = nodes.length; _l < _len3; i = ++_l) {
          b = nodes[i];
          eyes = b.eyes();
          result = evalUntilDepth(history.concat(b), opponent, depth - 1, alpha, beta);
          if (flag) {
            console.log("b" + i + " depth" + depth);
            console.log("alpha" + alpha.value + ", beta" + beta.value);
            console.log(b.toString());
            console.log(result.toString());
            console.log(result.value === beta.value);
          }
          if ((result.value < beta.value) || (result.value === beta.value && result.history.length < beta.history.length)) {
            beta = result;
          } else if (isNaN(result.value)) {
            if (nan == null) {
              nan = result;
            }
          }
          if (alpha.value >= beta.value) {
            return alpha;
          }
        }
        if ((nan != null) && beta.value > -MAX_SCORE) {
          return nan;
        }
        if (notPossibleToIterate && history.every(function(e, i) {
          return e === beta.history[i];
        })) {
          cache.add(next, board, beta);
        }
        if (beta.value === Infinity) {
          return nan;
        } else {
          return beta;
        }
    }
  };

  root = typeof exports !== "undefined" && exports !== null ? exports : typeof window !== "undefined" && window !== null ? window : {};

  _ref4 = ['compare', 'evaluate'];
  for (_k = 0, _len2 = _ref4.length; _k < _len2; _k++) {
    e = _ref4[_k];
    root[e] = eval(e);
  }

  self.onmessage = function(event) {
    var error, history, result, _ref5, _ref6;
    try {
      history = event.data.history.map(function(e) {
        return OnBoard.fromString(e);
      });
      if ((_ref5 = history[history.length - 2]) != null ? _ref5.isEqualTo(history[history.length - 1]) : void 0) {
        history[history.length - 2] = history[history.length - 1];
        if ((_ref6 = history[history.length - 3]) != null ? _ref6.isEqualTo(history[history.length - 1]) : void 0) {
          history[history.length - 3] = history[history.length - 1];
        }
      }
      if (event.data.size != null) {
        setBoardSize(event.data.size);
      }
      result = evaluate(history, event.data.next);
      event.data.value = result.value;
      return event.data.history = result.history.map(function(e) {
        return e.toString();
      });
    } catch (_error) {
      error = _error;
      return event.data.error = {
        line: error.line,
        message: error.message,
        sourceURL: error.sourceURL,
        stack: error.stack
      };
    } finally {
      postMessage(event.data);
      close();
    }
  };

}).call(this);
