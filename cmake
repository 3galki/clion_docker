#!/bin/sh

# домашний каталог установлен по умолчанию HOME=/Users/XXXX
BIN=$HOME/bin           # каталог, где будет расположен ваш cmake
LOG=$BIN/output         # результат выполнения - полезен для отладки
DEBUG=$BIN/debug        # журнал вызовов - полезен для отладки
SRC=$HOME/src           # каталог с исходниками, он будет проброшен в docker
CMAKE=cmake3            # команда для вызова cmake на удаленном хосте
MAKE="$BIN/make"

SSH="docker run -i --rm -v $SRC:$SRC:delegated -e HOME=$SRC hostname:5005/docker/clang-conan:5 /bin/sh"
#PREPARE="ln -s /usr/lib64/ccache $BIN; export PATH=\"$BIN:\$PATH\"; export CCACHE_DIR=$SRC/.ccache;"
PREPARE="mkdir $BIN; ln -s /usr/bin/clang++ $BIN; ln -s /usr/bin/clang $BIN;"
pwd >> $DEBUG
echo "$@" >> $DEBUG
if [ "$3" != "" ]; then
  case $3 in
    /private/*)
      echo "make=$MAKE" >> $DEBUG
      TMP=`mktemp -d $SRC/cmake.XXXXXX`
      trap "rm -rf $TMP" EXIT
      cp -rp $3/ $TMP
      COMMAND="$PREPARE cd $TMP/_build; $CMAKE \"$1\" \"$2\" .."
      echo "COMMAND=$COMMAND" >> $LOG
      echo $COMMAND | $SSH | tee -a $LOG
      sed -i .bak -e "s/CMAKE_MAKE_PROGRAM:FILEPATH=.*/CMAKE_MAKE_PROGRAM:FILEPATH=$MAKE/" $TMP/_build/CMakeCache.txt
      cp -rp $TMP/_build $3/
      ;;
    *)
      WD=`pwd`
      echo "Workdir: $WD" >> $DEBUG
      if [ ! -f $WD/../conanfile.txt -a ! -f $WD/../conanfile.py ]; then
        # собираем через альтернативный clang
        if [ $1 == "--build" ]; then
          /Applications/CLion.app/Contents/bin/cmake/bin/cmake $*
        else
          for cmd; do COMMAND="$COMMAND \"$cmd\""; done
          sh -c "/Applications/CLion.app/Contents/bin/cmake/bin/cmake -DCMAKE_C_COMPILER=$HOME/bin/clang -DCMAKE_CXX_COMPILER=$HOME/bin/clang++ $COMMAND"
        fi
      else
        WDS=_
        WDS="$WD$WDS"
        if [ $1 == "--build" ]; then
          COMMAND="$PREPARE mkdir -p /tmp$WD; rsync -a $WDS/ /tmp$WD; $CMAKE"
          for cmd; do if [ "$cmd" = "$WD" ]; then cmd=/tmp$WD; fi; COMMAND="$COMMAND \"$cmd\""; done
          COMMAND="$COMMAND; rsync -a /tmp/$WD/ $WDS"
        else
          COMMAND="$PREPARE cd $WD; conan install .. --build missing; $CMAKE"
          for cmd; do COMMAND="$COMMAND \"$cmd\""; done
          COMMAND="$COMMAND; mkdir -p /tmp$WD; mkdir -p $WDS; rsync -a $WDS/ /tmp$WD; cd /tmp$WD; cp $WD/conanbuildinfo.cmake /tmp$WD/; $CMAKE"
          for cmd; do if [ "$cmd" = "CodeBlocks - Unix Makefiles" ]; then cmd=Ninja; fi; COMMAND="$COMMAND \"$cmd\""; done
          COMMAND="$COMMAND; rsync -a /tmp$WD/ $WDS"
        fi
        echo "COMMAND=$COMMAND" >> $DEBUG
        echo "$COMMAND" | $SSH
      fi
      ;;
  esac
elif [ "$1" == "-version" ]; then
  echo "$CMAKE -version" | $SSH
else
  echo $SMAKE | $SSH
fi
