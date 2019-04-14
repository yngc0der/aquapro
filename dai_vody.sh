#!/bin/bash

host="https://aquapro.ua"

buy_url="/shop-cart/buy-now"
change_count_url="/shop-cart/change-count"
products_url="/shop-cart/products"
make_order_url="/shop-order"

default_water_id="87e0f5ec9337e73682a210242ab1df18"
silver_water_id="bedf8e4292f417b712505cc1cc5c077e"

source ./config.cfg

query() {
    local url=$1
    local data=$2
    local response=$(curl -s -X POST -L -H "x-requested-with: XMLHttpRequest" -c "/tmp/aquapro.cookie" -b "/tmp/aquapro.cookie" -d "${data}" ${url})
    echo $response
}

create_basket() {
    local response=$(query $host$buy_url "{}")
}

basket_empty() {
    local response=$(query $host$products_url "{}")
    if [ "${response}" == "[]" ]
    then
        return 1
    else
        return 0
    fi
}

product_count() {
    local product_id=$1
    local count=$2
    local response=$(query $host$change_count_url "product_id=${product_id}&count=${count}")
    if [ "${response}" == "{\"success\":true}" ]
    then
        return 0
    else
        return 1
    fi
}

form_data() {
    local data="exchangeBottle=${EXCHANGE_BOTTLE}&name=${NAME}&email=${EMAIL}&phone=${PHONE}&town=${ADDRESS}&comment=${COMMENT}&submit=Оформить%20заказ"
    echo $data
}

make_order() {
    local data=$(form_data)
    local response=$(query $host$make_order_url $data)
    echo $(echo "${response}" | grep -o -E '<h1>(.*)</h1>' | grep -o -E '№[0-9]+')
}

echo 'check the internet connection...'
if ( ! ( curl -fsS $host > /dev/null ) )
then
    echo 'failed!'
    exit
fi
echo "completed!"

echo "create basket..."
create_basket
if ( ! basket_empty )
then
    echo "failed!"
    exit
fi
echo "completed!"

echo "change products count..."
if ( ! ( product_count $default_water_id $DEFAULT_WATER && product_count $silver_water_id $SILVER_WATER ) )
then
    echo "failed!"
    exit
fi
echo "completed!"
echo "create order..."
order_number=$(make_order)
echo "created order ${order_number}"
