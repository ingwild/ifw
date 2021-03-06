rc.firewall
===========

Скипт для формирования правил Linux/Netfilter.

Применим для следующих конфигураций:

  - роутер со счетчиком траффика,
  - персональный файрвол,
  - файрвол, прикрывающий сеть с реальными или фиктивными IP-адресами.

1. Фичи.

  - Простая конфигурация;

  - Разумные дефолты;

  - Отладочный режим;

  - Поддержка любого количества внешних/внутренних интерфейсов,
    единственное ограничение: должен быть указан хотя бы один
    внешний или внутренний интерфейс;

  - Счетчик трафика на внешних интерфейсах.
    Входящий/исходящий трафик считается раздельно.
    Все засчитываемые пакеты проходят через ULOG,
    к которому можно подключить любой внешний софт (ulogd, ulog_acctd, ulogipac).
    Можно задать список внешних сеток/хостов, трафик с которыми не считается;

  - Список открытых TCP/UDP-портов;

  - Список сеток/хостов, форварды от/к которым фильтруются;

  - Список сеток/хостов, форварды от/к которым частично фильтруются
    (порты задаются отдельно);

  - Блеклист;

  - Поддержка DMZ, задается список пропускаемых внутрь портов;

  - Жесткая привязка IP-адресов к MAC-адресам;

  - Логгинг всех запрещенных пакетов через syslog;

  - Единствено нужный софт - bash, iptables
    (и любая внешняя ULOG-считалка, если нужно);

  - Неиспользуемые фичи никак не влияют на пути пакетов,
    они подключаются только в том случае, когда присутствуют
    соответствующие им конфигурационные файлы.

2. Интерфейсы и порты.

  Интерфейсы делятся на внутренние и внешние. Пакеты, в зависимости от того,
  с какого интерфейса пришли, дальше проходят по разным цепочкам.
  Попавшие на внешние - считаются, попавшие на внутренние - не считаются.
  Форварды (пакеты, не адресованные данному хосту, которые пробрасываются
  с одного интерфейса на другой), считаются так:

    - если пакет попал на внешний интерфейс - сразу засчитывается;
    - если пакет попал на внутренний интерфейс, определяется,
      с какого интерфейса он выйдет, если это внешний - считается;
    - все остальное не засчитываются.

  Если нужно маскарадить пакеты, которые проходят через внешние интерфейсы,
  их нужно задать отдельно. Множества внешних и маскарадящихся интерфейсов
  могут полностью совпадать в случае, если хост не прикрывает
  сеть с реальными IP-адресами.

  (!) Файл "if" должен существовать и содержать описание хотя бы одного
  внешнего или внутреннего интерфейса, а также содержать непересекающиеся
  множества, поскольку проверка на непересечение еще не реализована.

  По умолчанию хост полностью открыт со стороны внутренних интерфейсов,
  а со стороны внешних - полностью закрыт. В файле "open" указываются
  порты, которые нужно открыть для пакетов, адресованных этому хосту.

  В случае, если хост прикрывает клиентов с реальными IP-адресами (DMZ),
  нужно задать список портов, которые нужно пропускать внутрь (файл "pass").

  Внутренние интерфейсы - не маскарадятся, если нужно пробросить заданные порты
  из внешней сети во внутреннюю, существует зеркальное по отношению
  к маскараду преобразование адресов - DNAT. Правила проброса портов
  описываются в файле "dnat".

3. Хосты.

  Делятся на категории:

  1. Нормальные. Хост видят, и могут через него ходить дальше,
    в эту категорию по умолчанию попадают все клиенты из внутренних сеток
    (походы через платные интерфейсы считаются);

  2. Нормальные, но не полностью контроллируемые.
    Хост видят и форвардят, но некоторые порты наружу не выпускаются.
    Так, например, нежелательно выпускать наружу 25/tcp
    во избежание спам-рассылок из внутренней сети.
    Список таких хостов - в "softlist", список портов - в файле "nopass";

  3. Неконтроллируемые. Хост видят, но ходить через него не смогут,
    их список ведется в файле "hardlist" (попытки пролезть - режутся,
    и в счетчик не попадают). Предполагается, что таких клиентов можно
    выпускать во внешнюю сеть только через application level (proxy, socks);

  4. Опасные. Все пакеты от таких хостов режутся.
    Со стороны попавших в блеклист, хост, прикрываемый этим скриптом
    и сетки за ним - просто не видно. Не делается различий, внешний это хост
    или внутренний. Чем меньше этот список, тем лучше, поскольку меньше цепочек,
    через которые должны пройти пакеты от нормальных хостов.

  (!) 1-3 - внутренние хосты,
      4 - внутренние либо внешние.

  В случае, если присутствует файл "ethers", скрипт считает, что нужно вводить
  жесткую привязку соответствия MAC адреса IP адресу. В этом файле должны быть
  перечислены все известные MAC-адреса и соответствующие им IP-адреса.
  Пакеты от хостов с этими адресами принимаются, а от остальных хостов
  из внутренней сети - нет.

  (!) Если файл ethers есть, в нем должны быть перечислены все нужные адреса,
      иначе хост перестанет быть видимым из внутренней сети для тех
      хостов, которые не перечислены в файле "ethers".

4. Конфигурационные файлы.

  Полный список и зависимости:

    /etc/firewall
    |
    |-if          интерфейсы
    |  -open      порты, открытые со стороны внешних интерфейсов
    |  -pass      порты, разрешенные для форвардов во внутреннюю сеть
    |
    |-blacklist   хосты, которые не видят этот хост
    |
    |-hardlist    хосты, которым запрещено форвардить пакеты
    |
    |-softlist    хосты, которым частично запрещено форвардить пакеты
    |  -nopass    запрещенные порты для хостов из списка softlist
    |
    |-dnat        правила проброса портов во внутреннюю сеть
    |
    |-ethers      пары MAC- и IP-адресов, которым разрешено видеть этот хост
    |             со стороны внутренних интерфейсов
    |
    |-tarpit      хосты, попадающие в ловушку (TARPIT)
    |
    |-tports      порты, внешние коннекты на которые попадают в ловушку
    |
    |-mports      маркируемые порты
    |
    |-peers       хосты, участвующие в p2p обмене
    |
    |-pports      p2p порты
    |
    |-ulog        флажок, если присутствует - счетчик включен
    |  -noulog    хосты, траффик от которых не считается
    |
    |-log         флажок, если присутствует - включить логгинг
    |             всех запрещенных пакетов.

  Обязательный файл:

    if

  Необязательные файлы:

    blacklist, hardlist, softlist, open, pass, nopass, dnat, ethers,
    tarpit, tports, mports, peers, pports, log, ulog, noulog.

  Перечисление интерфейсов (if):

    Одна строчка = одна пара из названия интерфейса и названия типа
    (ext, int, masq), разделители - табуляции или пробелы. Название
    не обязательно должно представлять интерфейс, реально существующий
    в данный момент (как например ppp0, ppp1, которые появляются и исчезают).
    Перечислять больше чем может быть - нежелательно, поскольку цепочки
    правил все равно остаются после исчезновения интерфейса. Например:

    ppp0        ext
    eth0        int
    ppp0        masq

  Перечисления сетей/хостов (blacklist, hardlist, softlist, noulog, tarpit
    peers):

    Одна строчка = одна запись в CIDR-нотации. Например:

    10.1.1.51/32 - один хост,
    10.1.1.0/24 - сеть в интервале от 10.1.1.0 до 10.1.1.255.

  Перечисления портов (open, pass, nopass, tports, pports):

    Одна строчка = одна запись port/proto, где:
    port - номер порта в диапазоне от 1 до 65535, или интервал вида M-N, M<N,
    proto - название протокола (tcp или udp). Например:

    80/tcp
    53/udp

  Перечисление пар MAC- и IP-адресов (ethers):

    Одна строчка = одна пара адресов, разделитель - пробелы или табуляции,
    слева - MAC-адрес, справа - IP-адрес. Например:

    00:01:22:ab:cd:ef   10.1.1.51

  Перечисление редиректов (dnat):

    Одна строчка = одна пара значений port/proto и IP:port. Например:

    80/tcp      10.1.1.10:80

    или

    80/tcp      10.1.1.10

    (данные примеры равнозначны, поскольку если порты совпадают,
    второй раз номер порта можно не указывать)

  Перечисление маркируемых портов (mports):

    Одна строчка = одна пара значений port/proto и mark.
    mark представляет собой 16-ричное unsigned значение вида "0xFFFF".
    Например:

    80/tcp	0x10

  Файлы-флажки (log, ulog):

    Если такой файл есть - включается соответствующй модуль,
    если нет - не включается. При этом, то что в этом файле - не имеет значения.

6. Управление.

  Первый параметр (обязательный):

    <start> - включить фильтр,
    <stop> - выключить фильтр,
    <restart> - выключить/включить,
    <status> - дамп счетчиков iptables на экран,
    <dump> - дамп счетчиков iptables в /var/log/iptables.dump.

  Второй параметр (необязательный):

    <debug> - вместо запуска iptables, вывести на stdout все комманды,
    которые скрипт собирается запустить.

