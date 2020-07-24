package com.test;

import java.util.ArrayList;
import java.util.List;

public class Main {
    private static List<Node> list = new ArrayList<>();
    private static Integer header = 0;
    public static void main(String[] args) {
        {
            Node node = new Node(0, 0, list.size() + 1, 3);
            list.add(node);
            addNode(node);
        }
        {
            Node node = new Node(0, 0, list.size() + 1, 4);
            list.add(node);
            addNode(node);
        }
        {
            Node node = new Node(0, 0, list.size() + 1, 1);
            list.add(node);
            addNode(node);
        }
        {
            Node node = new Node(0, 0, list.size() + 1, 2);
            list.add(node);
            addNode(node);
        }

        Integer temp = header;
        for(; temp != 0;) {
            Node node = list.get(temp - 1);
            System.out.println(node.value);
            temp = node.nextIndex;
        }
    }

    public static void addNode(Node node) {
        if (list.size() == 1) {
            header = 1;
            return;
        }

        Node temp = list.get(header - 1);
        if (temp.value < node.value) {
            node.nextIndex = temp.currentIndex;
            temp.preIndex = node.currentIndex;
            header = node.currentIndex;
            return;
        }
        while (true) {
            if (temp.value < node.value) {
                node.nextIndex = temp.currentIndex;
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
                    temp = list.get(temp.nextIndex - 1);
                }
            }
        }
    }

    static class Node {
        Integer preIndex;

        Integer nextIndex;

        Integer currentIndex;

        Integer value;

        public Node(Integer preIndex, Integer nextIndex, Integer currentIndex, Integer value) {
            this.preIndex = preIndex;
            this.nextIndex = nextIndex;
            this.currentIndex = currentIndex;
            this.value = value;
        }
    }
}
