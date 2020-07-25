package com.test;

import java.util.ArrayList;
import java.util.List;

public class Main {
    private static List<Node> tradeNodeList = new ArrayList<>();
    private static Integer fc2usdtHeader = 0;
    private static Integer usdt2fcHeader = 0;
    public static void main(String[] args) {
        {
            Node node = new Node(0, 0, tradeNodeList.size() + 1, 3, 3);
            tradeNodeList.add(node);
            _addFc2usdtNode(node);
        }
        {
            Node node = new Node(0, 0, tradeNodeList.size() + 1, 4, 3);
            tradeNodeList.add(node);
            _addFc2usdtNode(node);
        }
        {
            Node node = new Node(0, 0, tradeNodeList.size() + 1, 1, 2);
            tradeNodeList.add(node);
            _addFc2usdtNode(node);
        }
        {
            Node node = new Node(0, 0, tradeNodeList.size() + 1, 2, 3);
            tradeNodeList.add(node);
            _addFc2usdtNode(node);
        }
        // =================》》》==============
        {
            Node node = new Node(0, 0, tradeNodeList.size() + 1, 3, 5);
            tradeNodeList.add(node);
            _addUsdt2fcNode(node);
        }

        _fc2usdtChange(tradeNodeList.size());

    }

    private static void _fc2usdtChange(int currentIndex) {

        Node node = tradeNodeList.get(currentIndex - 1);
        Node temp = tradeNodeList.get(usdt2fcHeader - 1);

        for (;;) {
            if (node.value > temp.value) {
                break;
            }


        }
    }

    public static void _addFc2usdtNode(Node node) {
        if (fc2usdtHeader == 0) {
            fc2usdtHeader = 1;
            return;
        }

        Node temp = tradeNodeList.get(fc2usdtHeader - 1);
        if (temp.value > node.value) {
            node.nextIndex = temp.currentIndex;
            temp.preIndex = node.currentIndex;
            fc2usdtHeader = node.currentIndex;
            return;
        }
        while (true) {
            if (temp.value > node.value) {
                node.nextIndex = temp.currentIndex;
                Node temp1 = tradeNodeList.get(temp.preIndex - 1);
                temp1.nextIndex = node.currentIndex;
                node.preIndex = temp.preIndex;
                temp.preIndex = node.currentIndex;
                break;
            } else {
                if (temp.nextIndex == 0) {
                    node.nextIndex = temp.nextIndex;
                    node.preIndex = temp.currentIndex;
                    temp.nextIndex = node.currentIndex;
                    break;
                } else {
                    temp = tradeNodeList.get(temp.nextIndex - 1);
                }
            }
        }
    }

    public static void _addUsdt2fcNode(Node node) {
        if (usdt2fcHeader == 0) {
            usdt2fcHeader = 1;
            return;
        }

        Node temp = tradeNodeList.get(usdt2fcHeader - 1);
        if (temp.value < node.value) {
            node.nextIndex = temp.currentIndex;
            temp.preIndex = node.currentIndex;
            usdt2fcHeader = node.currentIndex;
            return;
        }
        while (true) {
            if (temp.value < node.value) {
                node.nextIndex = temp.currentIndex;

                Node temp1 = tradeNodeList.get(temp.preIndex - 1);
                temp1.nextIndex = node.currentIndex;
                node.preIndex = temp.preIndex;
                temp.preIndex = node.currentIndex;
                break;
            } else {
                if (temp.nextIndex == 0) {
                    node.nextIndex = temp.nextIndex;
                    node.preIndex = temp.currentIndex;
                    temp.nextIndex = node.currentIndex;
                    break;
                } else {
                    temp = tradeNodeList.get(temp.nextIndex - 1);
                }
            }
        }
    }

    static class Node {
        Integer preIndex;

        Integer nextIndex;

        Integer currentIndex;

        Integer value;

        Integer num;

        public Node(Integer preIndex, Integer nextIndex, Integer currentIndex, Integer value, Integer num) {
            this.preIndex = preIndex;
            this.nextIndex = nextIndex;
            this.currentIndex = currentIndex;
            this.value = value;
            this.num = num;
        }
    }
}
